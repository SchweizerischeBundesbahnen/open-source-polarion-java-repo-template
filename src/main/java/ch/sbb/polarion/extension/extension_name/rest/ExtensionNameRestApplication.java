package ch.sbb.polarion.extension.extension_name.rest;

import ch.sbb.polarion.extension.extension_name.rest.controller.ApiController;
import ch.sbb.polarion.extension.extension_name.rest.controller.InternalController;
import ch.sbb.polarion.extension.generic.rest.GenericRestApplication;
import org.jetbrains.annotations.NotNull;

import java.util.Set;

public class ExtensionNameRestApplication extends GenericRestApplication {

    @Override
    protected @NotNull Set<Class<?>> getExtensionControllerClasses() {
        return Set.of(
                ApiController.class,
                InternalController.class
        );
    }

}
