package ch.sbb.polarion.extension.extension_name.rest.controller;

import ch.sbb.polarion.extension.generic.service.PolarionService;
import io.swagger.v3.oas.annotations.Hidden;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

import javax.inject.Singleton;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

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
