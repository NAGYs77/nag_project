package com.nag;

import java.io.BufferedReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class HistoryReader {

   
    public static List<String> readHistory() {
        String userHome = System.getProperty("user.home");
        Path historyPath = Paths.get(userHome, ".bash_history");

        List<String> cleanedCommands = new ArrayList<>();

        if (!Files.exists(historyPath)) {
            System.err.println("Le fichier .bash_history n'existe pas à l'emplacement : " + historyPath.toAbsolutePath());

            // Retourne une liste vide si le fichier n'existe pas
            return List.of(); 
        }

        try (BufferedReader reader = Files.newBufferedReader(historyPath)) {
            String line;
            String previousCommand = "";

            // Lecture ligne par ligne
            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();

                // Nettoyage : ignorer les lignes vides
                if (trimmed.isEmpty()) {
                    continue;
                }

                //  Nettoyage : ignorer les doublons consécutifs stricts
                if (!trimmed.equals(previousCommand)) {
                    cleanedCommands.add(trimmed);
                    previousCommand = trimmed;
                }
            }

            //  Inversion chronologique : placer les commandes les plus récentes en haut
            Collections.reverse(cleanedCommands);

        } catch (Exception e) {
            System.err.println("Erreur lors de la lecture du fichier .bash_history : " + e.getMessage());
        }

        return cleanedCommands;
    }
}