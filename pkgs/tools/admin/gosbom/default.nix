{ lib, stdenv, buildGoModule, fetchFromGitHub, installShellFiles }:

buildGoModule rec {
  pname = "gosbom";
  version = "0.80.0";

  src = fetchFromGitHub {
    owner = "nextlinux";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-q8xMa8Xw02+4w7zN1OkGbvd1NKZb3h4doFMuQzL2/x0=";
    # populate values that require us to use git. By doing this in postFetch we
    # can delete .git afterwards and maintain better reproducibility of the src.
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse HEAD > $out/COMMIT
      # 0000-00-00T00:00:00Z
      date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
  # hash mismatch with darwin
  proxyVendor = true;
  vendorHash = "sha256-QhxodA8Qlr33qYIrsQMKePlOcthS6cQMniHCpnewqcQ=";

  nativeBuildInputs = [ installShellFiles ];

  subPackages = [ "cmd/gosbom" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/nextlinux/gosbom/internal/version.version=${version}"
    "-X github.com/nextlinux/gosbom/internal/version.gitDescription=v${version}"
    "-X github.com/nextlinux/gosbom/internal/version.gitTreeState=clean"
  ];

  preBuild = ''
    ldflags+=" -X github.com/nextlinux/gosbom/internal/version.gitCommit=$(cat COMMIT)"
    ldflags+=" -X github.com/nextlinux/gosbom/internal/version.buildDate=$(cat SOURCE_DATE_EPOCH)"
  '';

  # tests require a running docker instance
  doCheck = false;

  postInstall = ''
    # avoid update checks when generating completions
    export GOSBOM_CHECK_FOR_APP_UPDATE=false

    installShellCompletion --cmd gosbom \
      --bash <($out/bin/gosbom completion bash) \
      --fish <($out/bin/gosbom completion fish) \
      --zsh <($out/bin/gosbom completion zsh)
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export GOSBOM_CHECK_FOR_APP_UPDATE=false
    $out/bin/gosbom --help
    $out/bin/gosbom version | grep "${version}"

    runHook postInstallCheck
  '';

  meta = with lib; {
    homepage = "https://github.com/nextlinux/gosbom";
    changelog = "https://github.com/nextlinux/gosbom/releases/tag/v${version}";
    description = "CLI tool and library for generating a Software Bill of Materials from container images and filesystems";
    longDescription = ''
      A CLI tool and Go library for generating a Software Bill of Materials
      (SBOM) from container images and filesystems. Exceptional for
      vulnerability detection when used with a scanner tool like GoVulners.
    '';
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ jk developer-guy ];
  };
}
