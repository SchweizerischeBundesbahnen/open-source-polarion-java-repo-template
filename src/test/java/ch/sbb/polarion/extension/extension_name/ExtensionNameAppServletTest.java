package ch.sbb.polarion.extension.extension_name;

import ch.sbb.polarion.extension.generic.GenericUiServlet;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ExtensionNameAppServletTest {

    @Test
    void instantiatesAsGenericUiServlet() {
        ExtensionNameAppServlet servlet = new ExtensionNameAppServlet();

        assertThat(servlet).isInstanceOf(GenericUiServlet.class);
    }
}
