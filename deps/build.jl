using BinDeps

@BinDeps.setup

libfdt = library_dependency("libfdt")

builddir = joinpath(BinDeps.depsdir(libfdt), "build")
src = joinpath(BinDeps.depsdir(libfdt), "src")
prefix = joinpath(BinDeps.depsdir(libfdt), "usr")
bindir = joinpath(prefix, "lib")
binpath = joinpath(bindir, "libfdt."*BinDeps.shlib_ext)

if isdir(builddir)
    rm(builddir, recursive = true)
end

if isdir(prefix)
    rm(prefix, recursive = true)
end

for path in [prefix, builddir, src, bindir]
    !isdir(path) && mkdir(path)
end

if !isfile(binpath)
    @unix_only begin
        cd(src)
        for mkcmd in (:gnumake, :gmake, :make)
            try
                if success(`$mkcmd`)
                    cp(joinpath(src, "libfdt.so"), binpath)
                    break
                end
            catch
                continue
            end
        end
    end

    @windows_only begin
        Base.warn("No build available on Windows yet.")
    end
end

provides(Binaries, bindir, libfdt)
@BinDeps.install [ :libfdt => :libfdt]
