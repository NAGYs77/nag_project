package com.nag;

import java.nio.file.Files;
import java.nio.file.Paths;
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

            BasicWindow window = new BasicWindow("Historique des commandes");
            Panel panel = new Panel(new LinearLayout(Direction.VERTICAL));

            List<String> historyCommands = HistoryReader.readHistory();

            if (historyCommands.isEmpty()) {
                panel.addComponent(new Label("Aucune commande trouvée dans l'historique."));
            } else {
                ActionListBox listBox = new ActionListBox(new TerminalSize(60, 12));

                for (String cmd : historyCommands) {
                    listBox.addItem(cmd, () -> {
                        selected[0] = cmd;
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