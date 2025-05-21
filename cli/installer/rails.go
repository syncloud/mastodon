package installer

import (
	"go.uber.org/zap"
	"os"
	"os/exec"
	"path"
	"strings"
)

type Rails struct {
	mastodonDir string
	railsBin    string
	logger      *zap.Logger
}

func NewRails(
	appDir string,
	logger *zap.Logger) *Rails {

	mastodonDir := path.Join(appDir, "ruby", "mastodon")
	return &Rails{
		mastodonDir: mastodonDir,
		railsBin:    path.Join(mastodonDir, "bin", "rails"),
		logger:      logger,
	}
}

func (e *Rails) Run(arg string) error {
	cmd := exec.Command(e.railsBin, arg)
	e.logger.Info("executing", zap.String("cmd", cmd.String()))
	cmd.Dir = e.mastodonDir
	cmd.Env = append(os.Environ(), "RAILS_ENV=production")
	out, err := cmd.CombinedOutput()
	e.logger.Info("command output")
	for _, line := range strings.Split(string(out), "\n") {
		e.logger.Info(line)
	}
	return err

}
