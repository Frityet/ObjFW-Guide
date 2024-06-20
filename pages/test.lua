local my_component = require("pages.test-component")

return {
    h2 {class="text-2xl font-bold text-center"} "This is a test page.";
    my_component {name="User"};
    p {class="text-center"} "This is a test page.";
}
