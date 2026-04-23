package io.elsci.chemikaze;

public class InvalidChemStructureException extends RuntimeException {
    private final String structure;

    public InvalidChemStructureException(String structure) {
        super("Invalid structure: " + structure);
        this.structure = structure;
    }
    public InvalidChemStructureException(String structure, String message) {
        super(message);
        this.structure = structure;
    }
    public InvalidChemStructureException(Exception cause) {
        this(null, cause);
    }
    public InvalidChemStructureException(String structure, Exception cause) {
        super("Invalid structure: " + structure, cause);
        this.structure = structure;
    }
    public InvalidChemStructureException(String structure, String message, Exception cause) {
        super(message, cause);
        this.structure = structure;
    }

    public String getStructure() {
        return structure;
    }
}
