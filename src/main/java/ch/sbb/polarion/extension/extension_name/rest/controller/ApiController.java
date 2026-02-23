package ch.sbb.polarion.extension.extension_name.rest.controller;

import ch.sbb.polarion.extension.generic.rest.filter.Secured;

import javax.inject.Singleton;
import javax.ws.rs.Path;

@Singleton
@Secured
@Path("/api")
public class ApiController extends InternalController {

    @Override
    public String hello() {
        return polarionService.callPrivileged(super::hello);
    }

}
