class Freecad < Formula
  include Language::Python::Virtualenv

  desc "Parametric 3D modeler"
  homepage "https://www.freecadweb.org"
  version "0.20.0"
  license "GPL-2.0-only"
  head "https://github.com/freecad/FreeCAD.git", branch: "master", shallow: false

  stable do
    url "https://github.com/FreeCAD/FreeCAD.git", using: :git, revision: "b4cb34c4d34d965838290490e478c16c84b655e7"
  end

  resource "cycler" do
    url "https://files.pythonhosted.org/packages/34/45/a7caaacbfc2fa60bee42effc4bcc7d7c6dbe9c349500e04f65a861c15eb9/cycler-0.11.0.tar.gz"
    sha256 "9c87405839a19696e837b3b818fed3f5f69f16f1eec1a1ad77e043dcea9c772f"
  end

  resource "kiwisolver" do
    url "https://files.pythonhosted.org/packages/2b/65/9eb6841880f6214f70e891a97ac945137bb6b2dd65ac35da219a752255fe/kiwisolver-1.4.2.tar.gz"
    sha256 "7f606d91b8a8816be476513a77fd30abe66227039bd6f8b406c348cb0247dcc9"
  end

  resource "matplotlib" do
    url "https://files.pythonhosted.org/packages/89/0c/653aec68e9cfb775c4fbae8f71011206e5e7fe4d60fcf01ea1a9d3bc957f/matplotlib-3.0.2.tar.gz"
    sha256 "c94b792af431f6adb6859eb218137acd9a35f4f7442cea57e4a59c54751c36af"
  end

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/64/4a/b008d1f8a7b9f5206ecf70a53f84e654707e7616a771d84c05151a4713e9/numpy-1.22.3.zip"
    sha256 "dbc7601a3b7472d559dc7b933b18b4b66f9aa7452c120e87dfb33d02008c8a18"
  end

  resource "pyparsing" do
    url "https://files.pythonhosted.org/packages/31/df/789bd0556e65cf931a5b87b603fcf02f79ff04d5379f3063588faaf9c1e4/pyparsing-3.0.8.tar.gz"
    sha256 "7bf433498c016c4314268d95df76c81b842a4cb2b276fa3312cfb1e1d85f6954"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/4c/c4/13b4776ea2d76c115c1d1b84579f3764ee6d57204f6be27119f13a61d0a9/python-dateutil-2.8.2.tar.gz"
    sha256 "0123cacc1627ae19ddf3c27a5de5bd67ee4586fbdd6440d9748f8abb483d3e86"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/71/39/171f1c67cd00715f190ba0b100d606d440a28c93c7714febeca8b79af85e/six-1.16.0.tar.gz"
    sha256 "1e61c37477a1626458e36f7b1d82aa5c9b094fa4802892072e49de9c60c4c926"
  end

  option "with-cloud", "Build with CLOUD module"
  option "with-unsecured-cloud", "Build with self signed certificate support CLOUD module"
  option "with-skip-web", "Disable web"

  depends_on "cmake" => :build
  depends_on "hdf5@1.10" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  depends_on "tbb" => :build
  depends_on "doxygen" => :build
  depends_on "boost"
  depends_on "boost-python3"
  depends_on "p3we/p3we/med-file"
  depends_on "p3we/p3we/nglib"
  depends_on "p3we/p3we/pyside@2"
  depends_on "p3we/p3we/coin3d"
  depends_on "opencascade"
  depends_on "openblas"
  depends_on "orocos-kdl"
  depends_on "python@3.9"
  depends_on "qt@5"
  depends_on "vtk@8.2"
  depends_on "xerces-c"

  def install
    # Create python virtual environment
    python = Formula["python@3.9"]
    python_ver = /\d\.\d+\.\d+/.match `#{python.opt_bin/"python3"} --version 2>&1`
    python_home = python.opt_prefix/"Frameworks/Python.framework/Versions/3.9"
    site_packages = Language::Python.site_packages(python.opt_bin/"python3")
    venv = virtualenv_create(prefix, python.opt_bin/"python3")
    venv.pip_install resources

    # Prepare cmake FindPython3.cmake module pointing to venv python
    (buildpath/"cMake/FindPython3.cmake").write <<-EOF
    include(FindPackageHandleStandardArgs)
    find_program(Python3_EXECUTABLE "python3" PATHS "#{prefix}/bin" NO_DEFAULT_PATH)
    find_library(Python3_LIBRARY NAMES "Python" "python3.9" PATHS "#{python_home}" PATH_SUFFIXES "lib" NO_DEFAULT_PATH)
    find_package_handle_standard_args(Python3 REQUIRED_VARS Python3_EXECUTABLE Python3_LIBRARY)
    if (Python3_FOUND)
      set(Python3_Interpreter_FOUND TRUE)
      set(Python3_LIBRARY_DIRS "#{python_home}/lib")
      set(Python3_INCLUDE_DIRS "#{python_home}/include/python3.9")
      set(Python3_LIBRARIES "${Python3_LIBRARY};-ldl;-framework CoreFoundation")
      set(Python3_VERSION "#{python_ver}")
      string(REPLACE "." ";" _Python3_VERSION ${Python3_VERSION})
      list(GET _Python3_VERSION 0 Python3_VERSION_MAJOR)
      list(GET _Python3_VERSION 1 Python3_VERSION_MINOR)
      list(GET _Python3_VERSION 2 Python3_VERSION_PATCH)
    endif()
    EOF

    # Disable function which are not available for Apple Silicon
    act = Hardware::CPU.arm? ? "OFF" : "ON"
    web = build.with?("skip-web") ? "OFF" : act

    args = std_cmake_args + %W[
      -DUSE_PYTHON3=1
      -DPython3_DIR=#{buildpath}/cMake
      -DINSTALL_TO_SITEPACKAGES=1
      -DFREECAD_USE_EXTERNAL_KDL=1
      -DBUILD_ENABLE_CXX_STD=C++17
      -DBUILD_WITH_CONDA=1
      -DBUILD_SMESH=1
      -DBUILD_WEB=#{web}
      -DBUILD_QT5=1
      -DBUILD_FEM=1
      -DBUILD_FEM_NETGEN=0
    ]

    args << "-DBUILD_CLOUD=1" if build.with? "cloud"
    args << "-DALLOW_SELF_SIGNED_CERTIFICATE=1" if build.with? "unsecured-cloud"

    mkdir "build" do
      system "cmake", "-S", "..", *args
      system "make", "-j#{ENV.make_jobs}", "install"
    end
  end

  test do
    # NOTE: make test more robust and accurate
    system "true"
  end
end
