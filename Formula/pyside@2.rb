class PysideAT2 < Formula
  include Language::Python::Virtualenv

  desc "Official Python bindings for Qt"
  homepage "https://wiki.qt.io/Qt_for_Python"
  url "https://download.qt.io/official_releases/QtForPython/pyside2/PySide2-5.15.3-src/pyside-setup-opensource-src-5.15.3.tar.xz"
  sha256 "7ff5f1cc4291fffb6d5a3098b3090abe4d415da2adec740b4e901893d95d7137"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-3.0-only"]
  revision 1

  uses_from_macos "libxml2"
  uses_from_macos "libxslt"

  depends_on "cmake" => :build
  depends_on "p3we/p3we/libclang"
  depends_on "python@3.9"
  depends_on "qt@5"

  # setup depends on packaging
  resource "packaging" do
    url "https://files.pythonhosted.org/packages/df/9e/d1a7217f69310c1db8fdf8ab396229f55a699ce34a203691794c5d1cad0c/packaging-21.3.tar.gz"
    sha256 "dd47c42927d89ab911e606518907cc2d3a1f38bbd026385970643f9c5b8ecfeb"
  end

  # Don't copy qt@5 tools.
  patch do
    url "https://src.fedoraproject.org/rpms/python-pyside2/raw/009100c67a63972e4c5252576af1894fec2e8855/f/pyside2-tools-obsolete.patch"
    sha256 "ede69549176b7b083f2825f328ca68bd99ebf8f42d245908abd320093bac60c9"
  end

  def install
    # pass through environ path to libclang headers and libs
    ENV["CLANG_INSTALL_DIR"] = Formula["p3we/p3we/libclang"].opt_prefix
    # fix Qt rcc path
    inreplace "build_scripts/platforms/unix.py" do |s|
      s.gsub! "{install_dir}/bin/rcc", "{qt_bin_dir}/rcc"
    end
    # build pyside2, shiboken and shiboken-generator via setuptools
    python = Formula["python@3.9"]
    python_venv = virtualenv_create(buildpath/"venv", python.opt_bin/"python3")
    python_venv.pip_install resources
    pyside_args = %W[
      --no-examples
      --shorter-paths
      --skip-docs
      --rpath=@loader_path/../shiboken2
      --parallel=#{ENV.make_jobs}
    ]
    system buildpath/"venv/bin/python3", *Language::Python.setup_install_args(prefix), *pyside_args
    # install tools symlinks
    qt = Formula["qt@5"]
    site_packages = Language::Python.site_packages(python.opt_bin/"python3")
    site_pyside = prefix/site_packages/"PySide2"
    %w[assistant linguist lupdate lrelease uic rcc].each do |x|
      ln_s (qt.opt_bin/x).relative_path_from(site_pyside), site_pyside
    end
    ln_s (qt.opt_libexec/"Designer.app").relative_path_from(site_pyside), site_pyside
    # fix shebangs
    %w[pyside2-designer pyside2-lupdate pyside2-rcc pyside2-uic shiboken2].each do |x|
      inreplace prefix/"bin"/x, %r{^#!.+python.*$}, "#!#{python.opt_bin}/python3"
    end
  end

  test do
    system Formula["python@3.9"].opt_bin/"python3", "-c", "import PySide2"
    system Formula["python@3.9"].opt_bin/"python3", "-c", "import shiboken2"

    modules = %w[
      Core
      Gui
      Location
      Multimedia
      Network
      Quick
      Svg
      Widgets
      Xml
    ]

    # Qt web engine is not supported on Apple Silicon.
    modules << "WebEngineWidgets" unless Hardware::CPU.arm?

    modules.each { |mod| system Formula["python@3.9"].opt_bin/"python3", "-c", "import PySide2.Qt#{mod}" }

    pyincludes = shell_output("#{Formula["python@3.9"].opt_bin}/python3-config --includes").chomp.split
    pylib = shell_output("#{Formula["python@3.9"].opt_bin}/python3-config --ldflags --embed").chomp.split
    pyver = Language::Python.major_minor_version(Formula["python@3.9"].opt_bin/"python3").to_s.delete(".")
    site_packages = prefix/Language::Python.site_packages("python3")

    (testpath/"test.cpp").write <<~EOS
      #include <shiboken.h>
      int main()
      {
        Py_Initialize();
        Shiboken::AutoDecRef module(Shiboken::Module::import("shiboken2"));
        assert(!module.isNull());
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++11", "test.cpp",
           "-I#{site_packages}/shiboken2_generator/include", "-L#{site_packages}/shiboken2",
           "-lshiboken2.cpython-#{pyver}-darwin.#{version.major_minor}",
           *pyincludes, *pylib, "-o", "test"
    system "./test"
  end
end
