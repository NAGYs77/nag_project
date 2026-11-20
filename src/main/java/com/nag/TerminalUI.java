package com.nag;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import com.googlecode.lanterna.TerminalSize;
import com.googlecode.lanterna.TextColor;
import com.googlecode.lanterna.graphics.SimpleTheme;
import com.googlecode.lanterna.gui2.ActionListBox;
import com.googlecode.lanterna.gui2.BasicWindow;
import com.googlecode.lanterna.gui2.Direction;
import com.googlecode.lanterna.gui2.Label;
import com.googlecode.lanterna.gui2.LinearLayout;
import com.googlecode.lanterna.gui2.MultiWindowTextGUI;
import com.googlecode.lanterna.gui2.Panel;
import com.googlecode.lanterna.gui2.Window;
import com.googlecode.lanterna.gui2.WindowBasedTextGUI;
import com.googlecode.lanterna.gui2.WindowListenerAdapter;
import com.googlecode.lanterna.input.KeyStroke;
import com.googlecode.lanterna.input.KeyType;
import com.googlecode.lanterna.screen.Screen;
import com.googlecode.lanterna.screen.TerminalScreen;
import com.googlecode.lanterna.terminal.DefaultTerminalFactory;
import com.googlecode.lanterna.terminal.Terminal;

public class TerminalUI {

    private final String outFile;
    private final String tmuxTarget;

    public TerminalUI(String outFile, String tmuxTarget) {
        this.outFile = outFile;
        this.tmuxTarget = tmuxTarget;
        run();
    }

    private void run() {
        String[] selected = new String[1];

        try {
            Terminal terminal = new DefaultTerminalFactory().createTerminal();
            Screen screen = new TerminalScreen(terminal);
            screen.startScreen();

            TerminalSize size = screen.getTerminalSize();
            int listWidth = Math.max(24, size.getColumns() - 6);
            int listHeight = Math.max(6, size.getRows() - 6);

            WindowBasedTextGUI textGUI = new MultiWindowTextGUI(screen);

            SimpleTheme theme = SimpleTheme.makeTheme(
                    true,
                    TextColor.ANSI.WHITE,
                    TextColor.ANSI.BLACK,
                    TextColor.ANSI.WHITE,
                    TextColor.ANSI.BLACK,
                    TextColor.ANSI.WHITE,
                    new TextColor.RGB(30, 90, 200),
                    TextColor.ANSI.BLACK
            );
            textGUI.setTheme(theme);

            String nagLine = System.getenv("NAG_LINE");
            List<String> items = new ArrayList<>();
            String title = "Historique des commandes";

            if (nagLine != null && !nagLine.isBlank()) {
                List<HistoryReader.Entry> entries = HistoryReader.read(nagLine);
                if (!entries.isEmpty()) {
                    title = "Aide : " + nagLine.trim();
                    for (HistoryReader.Entry e : entries) {
                        String label = e.description().isEmpty()
                                ? e.name()
                                : e.name() + " — " + e.description();
                        items.add(label);
                    }
                }
            }

            if (items.isEmpty()) {
                items.addAll(HistoryReader.readHistory());
            }

            BasicWindow window = new BasicWindow(title);
            Panel panel = new Panel(new LinearLayout(Direction.VERTICAL));

            if (items.isEmpty()) {
                panel.addComponent(new Label("Aucune suggestion disponible."));
            } else {
                ActionListBox listBox = new ActionListBox(new TerminalSize(listWidth, listHeight));

                for (String item : items) {
                    String insertValue = extractInsertValue(item, nagLine);
                    listBox.addItem(item, () -> {
                        selected[0] = insertValue;
                        window.close();
                    });
                }
                panel.addComponent(listBox);
            }

            window.setComponent(panel);

            window.addWindowListener(new WindowListenerAdapter() {
                @Override
                public void onInput(Window basePane, KeyStroke keyStroke, AtomicBoolean deliverEvent) {
                    KeyType type = keyStroke.getKeyType();
                    if (type == KeyType.Delete || type == KeyType.Backspace || type == KeyType.Escape) {
                        window.close();
                        deliverEvent.set(false);
                    }
                }
            });

            textGUI.addWindowAndWait(window);
            screen.stopScreen();

        } catch (Exception e) {
            System.err.println("Erreur dans l'interface Lanterna : " + e.getMessage());
        }

        if (selected[0] != null) {
            deliver(selected[0]);
        }
    }

    private String extractInsertValue(String displayItem, String nagLine) {
        if (nagLine != null && !nagLine.isBlank()) {
            int sep = displayItem.indexOf(" — ");
            String nameOnly = (sep > 0) ? displayItem.substring(0, sep).trim() : displayItem.trim();
            return " " + nameOnly;
        }
        return displayItem;
    }

    private void deliver(String cmd) {
        try {
            if (tmuxTarget != null) {
                new ProcessBuilder("tmux", "send-keys", "-t", tmuxTarget, "-l", cmd)
                        .inheritIO()
                        .start()
                        .waitFor();
            } else if (outFile != null) {
                Files.writeString(Paths.get(outFile), cmd);
            } else {
                System.out.println(cmd);
            }
        } catch (Exception e) {
            System.err.println("Erreur lors de l'envoi de la commande : " + e.getMessage());
        }
    }
}