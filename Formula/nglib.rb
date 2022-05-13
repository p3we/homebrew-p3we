class Nglib < Formula
  desc "C++ Library of NETGEN's tetrahedral mesh generator"
  homepage "https://github.com/ngsolve/netgen"
  url "https://github.com/ngsolve/netgen.git",
    tag:      "v6.2.2203",
    revision: "e8ec2b3550fe8c90d865cc7d012fba91d1153d51"
  license "LGPL-2.1-only"
  revision 1
  head "https://github.com/ngsolve/netgen.git", branch: "master"

  option "with-python", "Build with python binding"

  depends_on "cmake" => :build
  depends_on "opencascade"
  depends_on "python@3.9" if build.with? "python"
  depends_on "pybind11" if build.with? "python"
  depends_on "numpy" if build.with? "python"

  uses_from_macos "zlib"

  def install
    ENV["NETGENDIR"] = prefix/"bin"

    python = Formula["python@3.9"]
    site_packages = Language::Python.site_packages(python.opt_bin/"python3")
    args = std_cmake_args + %W[
      -DUSE_PYTHON=#{(build.with? 'python')? 'ON' : 'OFF'}
      -DUSE_GUI=OFF
      -DUSE_OCC=ON
      -DUSE_SUPERBUILD=OFF
      -DPYTHON_EXECUTABLE=#{python.opt_bin/'python3'}
      -DNG_INSTALL_DIR_BIN=bin
      -DNG_INSTALL_DIR_LIB=lib
      -DNG_INSTALL_DIR_CMAKE=lib/cmake/netgen
      -DNG_INSTALL_DIR_PYTHON=#{site_packages}
      -DNG_INSTALL_DIR_INCLUDE=include
      -DNG_INSTALL_DIR_RES=share
      -DSKBUILD=ON
    ]

    mkdir "Build" do
      system "cmake", *args, ".."
      system "make", "-j#{ENV.make_jobs}", "install"
    end
  end

  test do
    system "true"
  end
end
