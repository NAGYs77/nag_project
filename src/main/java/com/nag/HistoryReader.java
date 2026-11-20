package com.nag;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class HistoryReader {

    public record Entry(String name, String description) {}

    private static final Pattern SAFE = Pattern.compile("[A-Za-z0-9_.-]+");

    private static final Pattern SUB = Pattern.compile(
            "^\\s{1,12}([a-z][a-z0-9_-]*)\\*?(?:,\\s*[a-z][a-z0-9_-]*\\*?)?\\s{2,}(\\S.*)$");

    private static final Pattern LONG_OPT = Pattern.compile(
            "^\\s{1,12}(?:-[A-Za-z0-9],?\\s+)?(--[A-Za-z0-9][A-Za-z0-9-]*)"
            + "(?:[=\\[<]\\S*)?(?:\\s+(?:<[^>]+>|[A-Z][A-Z0-9_-]*))?\\s{2,}(\\S.*)$");

    private static final Pattern SHORT_OPT = Pattern.compile(
            "^\\s{1,12}(-[A-Za-z0-9])(?:\\s+(?:<[^>]+>|[A-Z][A-Z0-9_-]*))?\\s{2,}(\\S.*)$");

    // Repli souple pour les sorties d'aide moins conventionnelles (ex. certains outils/sous-commandes)
    private static final Pattern FALLBACK_OPT = Pattern.compile(
            "^\\s{1,16}(-[A-Za-z0-9-]{1,32})(?:[=\\s]+\\S+)?\\s+(\\S.*)$");

    private static final Pattern FALLBACK_CMD = Pattern.compile(
            "^\\s{1,16}([a-z][a-z0-9_-]{1,31})\\s+(\\S.*)$");

    public static List<Entry> read(String line) {
        if (line == null) {
            return List.of();
        }
        String trimmed = line.trim();
        if (trimmed.isEmpty()) {
            return List.of();
        }

        boolean endsWithSpace = Character.isWhitespace(line.charAt(line.length() - 1));
        String[] tokens = trimmed.split("\\s+");

        String cmdToken = tokens[0];
        if (!SAFE.matcher(cmdToken).matches() || !existsInPath(cmdToken)) {
            return List.of();
        }

        String prefixFilter = "";
        List<String> baseTokens;
        if (!endsWithSpace && tokens.length >= 2) {
            prefixFilter = tokens[tokens.length - 1];
            baseTokens = Arrays.asList(tokens).subList(0, tokens.length - 1);
        } else {
            baseTokens = Arrays.asList(tokens);
        }

        for (String t : baseTokens) {
            if (!SAFE.matcher(t).matches()) {
                return List.of();
            }
        }

        String[] baseArray = baseTokens.toArray(new String[0]);
        List<List<String>> attempts = new ArrayList<>();
        if (baseArray.length == 1 && baseArray[0].equals("git")) {
            attempts.add(List.of("git", "help"));
        }
        attempts.add(withArg(baseArray, "--help"));
        attempts.add(withArg(baseArray, "-h"));

        List<Entry> result = List.of();
        for (List<String> cmd : attempts) {
            List<Entry> found = run(cmd);
            if (!found.isEmpty()) {
                result = found;
                break;
            }
        }

        if (result.isEmpty() || prefixFilter.isEmpty()) {
            return result;
        }

        String lowerPrefix = prefixFilter.toLowerCase();
        List<Entry> filtered = new ArrayList<>();
        for (Entry e : result) {
            if (e.name().toLowerCase().startsWith(lowerPrefix)) {
                filtered.add(e);
            }
        }
        return filtered.isEmpty() ? result : filtered;
    }

    public static List<String> readHistory() {
        String histFileEnv = System.getenv("HISTFILE");
        Path historyPath = (histFileEnv != null && !histFileEnv.isBlank())
                ? Paths.get(histFileEnv)
                : Paths.get(System.getProperty("user.home"), ".bash_history");

        if (!Files.isRegularFile(historyPath) || !Files.isReadable(historyPath)) {
            return List.of();
        }

        try {
            List<String> rawLines = Files.readAllLines(historyPath, StandardCharsets.UTF_8);
            Set<String> uniqueRecent = new LinkedHashSet<>();

            for (int i = rawLines.size() - 1; i >= 0; i--) {
                String cmd = rawLines.get(i).trim();
                if (cmd.isEmpty() || cmd.startsWith("#")) {
                    continue;
                }
                uniqueRecent.add(cmd);
                if (uniqueRecent.size() >= 200) {
                    break;
                }
            }

            return new ArrayList<>(uniqueRecent);
        } catch (Exception e) {
            return List.of();
        }
    }

    private static List<String> withArg(String[] tokens, String arg) {
        List<String> cmd = new ArrayList<>(Arrays.asList(tokens));
        cmd.add(arg);
        return cmd;
    }

    private static boolean existsInPath(String cmd) {
        String path = System.getenv("PATH");
        if (path == null) {
            return false;
        }
        for (String dir : path.split(File.pathSeparator)) {
            if (dir.isEmpty()) {
                continue;
            }
            Path p = Paths.get(dir, cmd);
            if (Files.isRegularFile(p) && Files.isExecutable(p)) {
                return true;
            }
        }
        return false;
    }

    private static List<Entry> run(List<String> cmd) {
        Path tmp = null;
        try {
            tmp = Files.createTempFile("nag-help", ".txt");
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.redirectErrorStream(true);
            pb.redirectOutput(tmp.toFile());
            pb.redirectInput(ProcessBuilder.Redirect.from(new File("/dev/null")));
            pb.environment().put("PAGER", "cat");
            pb.environment().put("MANPAGER", "cat");
            pb.environment().put("GIT_PAGER", "cat");
            pb.environment().put("TERM", "dumb");
            pb.environment().put("NO_COLOR", "1");

            Process p = pb.start();
            if (!p.waitFor(5, TimeUnit.SECONDS)) {
                p.destroyForcibly();
                return List.of();
            }

            String text = new String(Files.readAllBytes(tmp), StandardCharsets.UTF_8);
            return parse(Arrays.asList(text.split("\\R")));
        } catch (Exception e) {
            return List.of();
        } finally {
            if (tmp != null) {
                try {
                    Files.deleteIfExists(tmp);
                } catch (Exception ignored) {
                }
            }
        }
    }

    private static List<Entry> parse(List<String> lines) {
        Comparator<Entry> byName = Comparator.comparing(Entry::name, String.CASE_INSENSITIVE_ORDER);

        Map<String, Entry> subs = new LinkedHashMap<>();
        Map<String, Entry> longOpts = new LinkedHashMap<>();
        Map<String, Entry> shortOpts = new LinkedHashMap<>();

        for (String l : lines) {
            Matcher m = SUB.matcher(l);
            if (m.matches()) {
                String cleanDesc = m.group(2).trim().replaceAll("\\s+", " ");
                subs.putIfAbsent(m.group(1), new Entry(m.group(1), cleanDesc));
                continue;
            }
            m = LONG_OPT.matcher(l);
            if (m.matches()) {
                String cleanDesc = m.group(2).trim().replaceAll("\\s+", " ");
                longOpts.putIfAbsent(m.group(1), new Entry(m.group(1), cleanDesc));
                continue;
            }
            m = SHORT_OPT.matcher(l);
            if (m.matches()) {
                String cleanDesc = m.group(2).trim().replaceAll("\\s+", " ");
                shortOpts.putIfAbsent(m.group(1), new Entry(m.group(1), cleanDesc));
            }
        }

        if (subs.isEmpty() && longOpts.isEmpty() && shortOpts.isEmpty()) {
            for (String l : lines) {
                Matcher m = FALLBACK_OPT.matcher(l);
                if (m.matches()) {
                    String name = m.group(1);
                    String desc = m.group(2).trim().replaceAll("\\s+", " ");
                    if (name.startsWith("--")) {
                        longOpts.putIfAbsent(name, new Entry(name, desc));
                    } else {
                        shortOpts.putIfAbsent(name, new Entry(name, desc));
                    }
                    continue;
                }
                m = FALLBACK_CMD.matcher(l);
                if (m.matches()) {
                    String name = m.group(1);
                    String desc = m.group(2).trim().replaceAll("\\s+", " ");
                    subs.putIfAbsent(name, new Entry(name, desc));
                }
            }
        }

        List<Entry> sortedSubs = new ArrayList<>(subs.values());
        sortedSubs.sort(byName);

        List<Entry> sortedLong = new ArrayList<>(longOpts.values());
        sortedLong.sort(byName);

        List<Entry> sortedShort = new ArrayList<>(shortOpts.values());
        sortedShort.sort(byName);

        List<Entry> all = new ArrayList<>(sortedSubs.size() + sortedLong.size() + sortedShort.size());
        all.addAll(sortedSubs);
        all.addAll(sortedLong);
        all.addAll(sortedShort);
        return all;
    }
}