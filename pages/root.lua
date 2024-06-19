local xml_gen = require("xml-generator")
local xml = xml_gen.xml

return function (name, ...)
    return xml.html {charset="utf-8", lang="en"} {
        xml.head {
            xml.title { name };
            xml.meta {name="viewport", content="width=device-width, initial-scale=1"};
            xml.script {src="https://cdn.tailwindcss.com"};
        },
        xml.body {
            xml.div {class="container mx-auto"} {...};
        }
    }
end
