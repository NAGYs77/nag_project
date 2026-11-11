package com.nag;

public class Main {
    public static void main(String[] args) {
        System.out.println("nag démarre...");
        HistoryReader.readHistory();
        new TerminalUI();
    }
}