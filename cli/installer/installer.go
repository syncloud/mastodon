package installer

import (
	"fmt"
	"github.com/google/uuid"
	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
	"os"
	"path"
)

const (
	App      = "mastodon"
	PsqlPort = 5434
)

type Variables struct {
	AppDir                                  string
	CommonDir                               string
	DatabaseDir                             string
	DbPsqlPort                              int
	DbName                                  string
	DbUser                                  string
	DbPassword                              string
	StorageDir                              string
	DataDir                                 string
	AppUrl                                  string
	AppDomain                               string
	Secret                                  string
	SecretBase                              string
	ActiveRecordEncryptionDeterministicKey  string
	ActiveRecordEncryptionKeyDerivationSalt string
	ActiveRecordEncryptionPrimaryKey        string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	configDir          string
	appDir             string
	dataDir            string
	commonDir          string
	mastodonDir        string
	railsBin           string
	platformClient     *platform.Client
	database           *Database
	installFile        string
	executor           *Executor
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	appDir := fmt.Sprintf("/snap/%s/current", App)
	dataDir := fmt.Sprintf("/var/snap/%s/current", App)
	commonDir := fmt.Sprintf("/var/snap/%s/common", App)
	mastodonDir := path.Join(appDir, "ruby", "mastodon")
	railsBin := path.Join(mastodonDir, "bin", "rails")

	configDir := path.Join(dataDir, "config")

	executor := NewExecutor(logger)
	return &Installer{
		newVersionFile:     path.Join(appDir, "version"),
		currentVersionFile: path.Join(dataDir, "version"),
		configDir:          configDir,
		appDir:             appDir,
		dataDir:            dataDir,
		commonDir:          commonDir,
		mastodonDir:        mastodonDir,
		railsBin:           railsBin,
		platformClient:     platform.New(),
		database:           NewDatabase(appDir, dataDir, configDir, App, executor, logger),
		installFile:        path.Join(commonDir, "installed"),
		executor:           executor,
		logger:             logger,
	}
}

func (i *Installer) Install() error {

	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) Configure() error {
	if i.IsInstalled() {
		err := i.Upgrade()
		if err != nil {
			return err
		}
	} else {
		err := i.Initialize()
		if err != nil {
			return err
		}
	}

	return nil
}

func (i *Installer) IsInstalled() bool {
	_, err := os.Stat(i.installFile)
	return err == nil
}

func (i *Installer) Initialize() error {
	_, err := i.StorageChange()
	if err != nil {
		return err
	}

	err = i.database.Execute(
		"postgres",
		fmt.Sprintf("ALTER USER %s WITH PASSWORD '%s'", App, App),
	)
	if err != nil {
		return err
	}

	//err = i.database.createDbIfMissing(App)
	//if err != nil {
	//	return err
	//}

	err = i.executor.Run(i.railsBin, i.mastodonDir, "db:setup")
	if err != nil {
		return err
	}
	err = i.executor.Run(i.railsBin, i.mastodonDir, "db:migrate")
	if err != nil {
		return err
	}

	//err = i.database.Execute("postgres", fmt.Sprintf("GRANT CREATE ON SCHEMA public TO %s", App))
	//if err != nil {
	//	return err
	//}

	err = os.WriteFile(i.installFile, []byte("installed"), 0644)
	if err != nil {
		return err
	}

	return i.UpdateVersion()
}

func (i *Installer) Upgrade() error {
	err := i.database.Restore()
	if err != nil {
		return err
	}
	_, err = i.StorageChange()
	if err != nil {
		return err
	}
	//err = i.database.createDbIfMissing(App)
	//if err != nil {
	//	return err
	//}
	err = i.executor.Run(i.railsBin, i.mastodonDir, "db:migrate")
	if err != nil {
		return err
	}
	return i.UpdateVersion()
}

func (i *Installer) PreRefresh() error {
	return i.database.Backup()
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}
	err = i.database.Remove()
	if err != nil {
		return err
	}
	err = i.database.Init()
	if err != nil {
		return err
	}
	err = i.database.InitConfig()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}
	return nil

}
func (i *Installer) AccessChange() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}
	return err
}

func (i *Installer) StorageChange() (string, error) {
	return i.platformClient.InitStorage(App, App)
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {
	err := linux.CreateUser(App)
	if err != nil {
		return err
	}

	storageDir, err := i.StorageChange()
	if err != nil {
		return err
	}

	err = linux.CreateMissingDirs(
		path.Join(i.dataDir, "nginx/cache"),
		path.Join(i.dataDir, "redis"),
		path.Join(i.dataDir, "system"),
	)
	if err != nil {
		return err
	}

	url, err := i.platformClient.GetAppUrl(App)
	if err != nil {
		return err
	}

	domain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}

	secret, err := getOrCreateUuid(path.Join(i.dataDir, ".secret"))
	if err != nil {
		return err
	}

	secretBase, err := getOrCreateUuid(path.Join(i.dataDir, ".secret.base"))
	if err != nil {
		return err
	}

	activeRecordEncryptionDeterministicKey, err := getOrCreateUuid(path.Join(i.dataDir, ".activeRecordEncryptionDeterministicKey"))
	if err != nil {
		return err
	}
	activeRecordEncryptionKeyDerivationSalt, err := getOrCreateUuid(path.Join(i.dataDir, ".activeRecordEncryptionKeyDerivationSalt"))
	if err != nil {
		return err
	}
	activeRecordEncryptionPrimaryKey, err := getOrCreateUuid(path.Join(i.dataDir, ".activeRecordEncryptionPrimaryKey"))
	if err != nil {
		return err
	}

	variables := Variables{
		AppDir:                                  i.appDir,
		CommonDir:                               i.commonDir,
		DatabaseDir:                             i.database.DatabaseDir(),
		DbPsqlPort:                              PsqlPort,
		DbName:                                  App,
		DbUser:                                  App,
		DbPassword:                              App,
		StorageDir:                              storageDir,
		DataDir:                                 i.dataDir,
		AppUrl:                                  url,
		AppDomain:                               domain,
		Secret:                                  secret,
		SecretBase:                              secretBase,
		ActiveRecordEncryptionDeterministicKey:  activeRecordEncryptionDeterministicKey,
		ActiveRecordEncryptionKeyDerivationSalt: activeRecordEncryptionKeyDerivationSalt,
		ActiveRecordEncryptionPrimaryKey:        activeRecordEncryptionPrimaryKey,
	}

	err = config.Generate(
		path.Join(i.appDir, "config"),
		path.Join(i.dataDir, "config"),
		variables,
	)
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	return nil

}

func (i *Installer) FixPermissions() error {
	err := linux.Chown(i.dataDir, App)
	if err != nil {
		return err
	}
	err = linux.Chown(i.commonDir, App)
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	return i.PostRefresh()
}

func (i *Installer) RestorePostStart() error {
	return i.Configure()
}

func getOrCreateUuid(file string) (string, error) {
	_, err := os.Stat(file)
	if os.IsNotExist(err) {
		secret := uuid.New().String()
		err = os.WriteFile(file, []byte(secret), 0644)
		return secret, err
	}
	content, err := os.ReadFile(file)
	if err != nil {
		return "", err
	}
	return string(content), nil
}
