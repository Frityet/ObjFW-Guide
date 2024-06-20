local xml_gen = require("xml-generator")
local xml = xml_gen.xml

math.randomseed(os.time())

return xml_gen.component(function (args)
    return xml.div {class="bg-gray-200 p-4"} {
        xml.h1 {class="text-2xl font-bold"} {"Hello, ", args.name, "!"},
        xml.p {class="text-lg"} {"This is a random number: ", math.random(1, 100)},
    }
end)
