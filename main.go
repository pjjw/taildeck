package main

import (
	"archive/tar"
	"compress/gzip"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

var (
	out           = flag.String("out", ".", "where to save squashfs images to")
	tsTarballPath = flag.String("tarball", "./var/tailscale_1.24.2_amd64.tgz", "path to tailscale tarball on disk")
	distro        = flag.String("distro", "steamos", "distro to stamp into system extension")

	//go:embed tailscaled.service
	systemdService []byte
)

func main() {
	flag.Parse()

	fin, err := os.Open(*tsTarballPath)
	if err != nil {
		log.Fatal(err)
	}

	gzRdr, err := gzip.NewReader(fin)
	if err != nil {
		log.Fatal(err)
	}

	tarFin := tar.NewReader(gzRdr)

	tmpDir, err := os.MkdirTemp("", "taildeck-builder")
	if err != nil {
		log.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	os.MkdirAll(filepath.Join(tmpDir, "usr", "bin"), 0755)
	os.MkdirAll(filepath.Join(tmpDir, "usr", "sbin"), 0755)
	os.MkdirAll(filepath.Join(tmpDir, "usr", "lib", "systemd", "system"), 0755)
	os.MkdirAll(filepath.Join(tmpDir, "usr", "lib", "extension-release.d"), 0755)

	for {
		hdr, err := tarFin.Next()
		if err != nil {
			if err == io.EOF {
				break
			}
			log.Fatal(err)
		}

		log.Printf("%s (%s): %d bytes", hdr.Name, strconv.FormatInt(hdr.Mode, 8), hdr.Size)

		var fname string

		switch filepath.Base(hdr.Name) {
		case "tailscale":
			fname = filepath.Join(tmpDir, "usr", "bin", "tailscale")
		case "tailscaled":
			fname = filepath.Join(tmpDir, "usr", "sbin", "tailscaled")
		default:
			continue
		}

		fout, err := os.Create(fname)
		if err != nil {
			log.Fatal(err)
		}

		_, err = io.Copy(fout, tarFin)
		if err != nil {
			log.Fatal(err)
		}

		fout.Chmod(0755)

		err = fout.Close()
		if err != nil {
			log.Fatal(err)
		}
	}

	fout, err := os.Create(filepath.Join(tmpDir, "usr", "lib", "extension-release.d", "extension-release.tailscale"))
	if err != nil {
		log.Fatal(err)
	}

	fmt.Fprintln(fout, "SYSEXT_LEVEL=1.0")
	fmt.Fprintln(fout, "VERSION_ID=3.2")
	fmt.Fprintf(fout, "ID=%s", *distro)

	err = fout.Close()
	if err != nil {
		log.Fatal(err)
	}

	fout, err = os.Create(filepath.Join(tmpDir, "usr", "lib", "systemd", "system", "tailscaled.service"))
	if err != nil {
		log.Fatal(err)
	}

	_, err = fout.Write(systemdService)
	if err != nil {
		log.Fatal(err)
	}

	err = fout.Close()
	if err != nil {
		log.Fatal(err)
	}

	binPath, err := exec.LookPath("mksquashfs")
	if err != nil {
		log.Fatal(err)
	}

	sp := strings.Split(filepath.Base(*tsTarballPath), "_")
	cmd := exec.Command(binPath, tmpDir, fmt.Sprintf("%s/tailscale_sysext_%s.raw", *out, sp[1]), "-quiet", "-noappend", "-all-root", "-root-mode", "755", "-b", "1M", "-comp", "xz", "-Xdict-size", "100%")
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	if err := cmd.Run(); err != nil {
		log.Fatal(err)
	}
}
