package io.elsci.chemikaze.core;

public class InvalidElementException extends RuntimeException {
    public final String element;

    public InvalidElementException(String element) {
        super("Unrecognized element: " + element);
        this.element = element;
    }
}
