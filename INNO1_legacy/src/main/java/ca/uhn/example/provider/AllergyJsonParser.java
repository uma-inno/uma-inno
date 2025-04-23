package ca.uhn.example.provider;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Iterator;

public class AllergyJsonParser {

    // Methode zum Parsen einer direkten "AllergyIntolerance"-Ressource
    public static void parseAllergyData(String jsonInput) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode rootNode = mapper.readTree(jsonInput);

            // Prüfen, ob es sich um eine AllergyIntolerance-Ressource handelt
            if ("AllergyIntolerance".equals(rootNode.path("resourceType").asText())) {
                System.out.println("=== AllergyIntolerance Information ===");
                parseAllFields(rootNode, "");
                System.out.println("----------------------------------");
            } else {
                System.out.println("Kein gültiger AllergyIntolerance-Datensatz gefunden.");
            }
        } catch (Exception e) {
            System.err.println("Error parsing JSON: " + e.getMessage());
        }
    }

    // Methode zur Ausgabe aller Felder und Werte auf einer Zeile
    private static void parseAllFields(JsonNode node, String prefix) {
        if (node.isObject()) {
            Iterator<String> fieldNames = node.fieldNames();
            while (fieldNames.hasNext()) {
                String fieldName = fieldNames.next();
                JsonNode field = node.get(fieldName);
                parseAllFields(field, prefix + fieldName + ": ");
            }
        } else if (node.isArray()) {
            for (JsonNode arrayElement : node) {
                parseAllFields(arrayElement, prefix);
            }
        } else {
            System.out.println(prefix + node.asText()); // Direkte Ausgabe mit Titel
        }
    }
}
