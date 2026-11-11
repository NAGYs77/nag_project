package com.nag;

public class Main {
    public static void main(String[] args) {
        String outFile = null;
        for (int i = 0; i < args.length - 1; i++) {
            if (args[i].equals("--out")) {
                outFile = args[i + 1];
            }
        }
        String tmuxTarget = System.getenv("NAG_TARGET");
        new TerminalUI(outFile, tmuxTarget);
    }
}