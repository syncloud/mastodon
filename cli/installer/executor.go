package installer

import (
	"go.uber.org/zap"
	"os/exec"
	"strings"
)

type Executor struct {
	logger *zap.Logger
}

func NewExecutor(logger *zap.Logger) *Executor {
	return &Executor{
		logger: logger,
	}
}

func (e *Executor) RunWithCwd(app string, cwd string, args ...string) error {
	cmd := exec.Command(app, args...)
	e.logger.Info("executing", zap.String("cmd", cmd.String()))
	cmd.Dir = cwd
	out, err := cmd.CombinedOutput()
	e.logger.Info("command output")
	for _, line := range strings.Split(string(out), "\n") {
		e.logger.Info(line)
	}
	return err

}

func (e *Executor) Run(app string, args ...string) error {
	return e.RunWithCwd(app, "", args...)
}
