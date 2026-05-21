package de.train.bewerbung;

public record EinreichenResult(
        int bewerbungId,
        int bewerberId,
        String vorgangsNr
) {}
