package ch.sbb.polarion.extension.extension_name.rest.controller;

import ch.sbb.polarion.extension.generic.service.PolarionService;
import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import jakarta.inject.Singleton;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Singleton
@Hidden
@Path("/internal")
@Tag(name = "Extension Name")
public class InternalController {

    protected final PolarionService polarionService = new PolarionService();

    @GET
    @Path("/hello")
    @Produces(MediaType.TEXT_PLAIN)
    @Operation(summary = "Returns a greeting message")
    public String hello() {
        return "Hello from extension-name!";
    }

}
