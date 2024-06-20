--Packages, you can use `xrepo search <name>` to search packages,
--and prefix with other package managers, for example `vcpkg::pcre2` in order to use their packages.
--Documentation: https://xmake.io/#/manual/global_interfaces?id=add_requires
local packages = {
    "luajit"
}

--Sanitizers to use when building in debug mode
local sanitizers = { "address", "leak", "undefined" }

--Objective C compilation flags
local mflags = {
    release = {},
    debug = {
        "-Wno-unused-function", "-Wno-unused-parameter", "-Wno-unused-variable"
    },
    regular = {
        "-Wall", "-Wextra", "-Werror",
    }
}

--Objective C linker flags
local ldflags = {
    release = {
        "-flto"
    },
    debug = {},
    regular = {}
}

option("tls")
do
    set_default(is_plat("macosx") and "securetransport" or "openssl")
    set_values("securetransport", "openssl", "gnutls", "mbedtls")
    set_showmenu(true)
    set_description("TLS backend to use")
end
option_end()

--C standard to use, `gnulatest` means the latest C standard + GNU extensions
set_languages("gnulatest")

add_requires(packages, { configs = { shared = is_kind("shared") } })
if is_config("tls", "securetransport") then
    if not is_plat("macosx") then
        raise("SecureTransport is only available on macOS")
    end

    add_requires("objfw", { configs = { shared = is_kind("shared"), tls = "securetransport" } })
elseif is_config("tls", "openssl") then
    add_requires("objfw", { configs = { shared = is_kind("shared"), tls = "openssl" } })
elseif is_config("tls", "gnutls") then
    add_requires("objfw", { configs = { shared = is_kind("shared"), tls = "gnutls" } })
elseif is_config("tls", "mbedtls") then
    add_requires("objfw", { configs = { shared = is_kind("shared"), tls = "mbedtls" } })
end

add_rules("mode.debug", "mode.release", "mode.check", "mode.minsizerel")

target("ObjFW-Guide-Server")
do
    set_kind("binary")
    add_packages("objfw")
    add_packages(packages)
    add_options("tls")

    add_files("src/**.m")
    add_headerfiles("src/**.h")

    add_mflags(mflags.regular)
    add_ldflags(ldflags.regular)

    if is_mode("debug", "check") then
        add_mflags(mflags.debug)
        add_ldflags(ldflags.debug)

        add_defines("PROJECT_DEBUG")
        if is_mode("check") then
            cprint("${yellow}WARNING: Sanitizers make ObjFW run extremely slow")
            for _, v in ipairs(sanitizers) do
                add_mflags("-fsanitize=" .. v)
                add_ldflags("-fsanitize=" .. v)
            end
        end
    elseif is_mode("release", "minsizerel") then
        add_mflags(mflags.release)
        add_ldflags(ldflags.release)
        if is_mode("minsizerel") then
            set_symbols("hidden")
            set_optimize("smallest")
            set_strip("all")
        end
    end
end
target_end()
