package ch.sbb.polarion.extension.extension_name;

import ch.sbb.polarion.extension.generic.GenericUiServlet;

import java.io.Serial;

/**
 * Serves the React single-page app from its own webapp context ({@code extension-name-app}). The admin
 * extenders in hivemodule.xml open it as
 * {@code /polarion/extension-name-app/ui/app/index.html?feature=<id>}; everything else about the
 * request handling comes from the generic servlet.
 */
public class ExtensionNameAppServlet extends GenericUiServlet {

    @Serial
    private static final long serialVersionUID = -6340825404777970325L;

    public ExtensionNameAppServlet() {
        super("extension-name-app");
    }
}
