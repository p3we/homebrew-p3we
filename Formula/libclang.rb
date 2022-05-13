class Libclang < Formula
  desc "LibClang is a stable high level C interface to clang"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/llvm-project-13.0.1.src.tar.xz"
  sha256 "326335a830f2e32d06d0a36393b5455d17dc73e0bd1211065227ee014f92cbf8"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    url :homepage
    regex(/LLVM (\d+\.\d+\.\d+)/i)
  end

  keg_only :provided_by_macos

  # https://llvm.org/docs/GettingStarted.html#requirement
  # We intentionally use Make instead of Ninja.
  # See: Homebrew/homebrew-core/issues/35513
  depends_on "cmake" => :build
  depends_on "make" => :build

  uses_from_macos "libedit"
  uses_from_macos "libffi", since: :catalina
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  def install
    args = std_cmake_args + %W[
      -DLLVM_ENABLE_PROJECTS=clang
      -DLLVM_BUILD_TOOLS=OFF
      -DLLVM_ENABLE_BINDINGS=OFF
      -DLLVM_ENABLE_EH=ON
      -DLLVM_ENABLE_FFI=ON
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_INSTALL_UTILS=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DPACKAGE_VENDOR=#{tap.user}
      -DBUG_REPORT_URL=#{tap.issues_url}
      -DCLANG_VENDOR_UTI=org.#{tap.user.downcase}.clang
    ]
    mkdir buildpath/"build" do
      system "cmake", "-G", "Unix Makefiles", "-S", buildpath/"llvm", *args
      system "cmake", "--build", ".", "--target", "install-clang-libraries", "--target", "install-clang-headers"
    end
  end

  def test
    (testpath/"test.c").write <<~EOS
      #include <clang-c/Index.h>
      int main()
      {
        clang_disposeIndex(clang_createIndex(0, 0));
      }
    EOS
    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lclang"
    system "./test"
  end
end
