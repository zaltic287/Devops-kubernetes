package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/gocolly/colly/v2"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/streadway/amqp"
	"gopkg.in/yaml.v2"
)

type Config struct {
	Rabbitmq struct {
		Host     string `yaml:"host"`
		Port     string `yaml:"port"`
		Vhost    string `yaml:"vhost"`
		User     string `yaml:"user"`
		Password string `yaml:"password"`
		Queue    string `yaml:"queue"`
	} `yaml:"rabbitmq"`
	Postgres struct {
		Host     string `yaml:"host"`
		Port     string `yaml:"port"`
		Database string `yaml:"database"`
		User     string `yaml:"user"`
		Password string `yaml:"password"`
	} `yaml:"postgresql"`
}

var userAgent = []string{
	"Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.2 Safari/605.1.15",
	"Mozilla/5.0 (Windows; U; Windows NT 6.2) AppleWebKit/532.6.2 (KHTML, like Gecko) Version/5.0.4 Safari/532.6.2",
	"Mozilla/5.0 (Linux; Android 8.1.0; TECNO F4 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36 EdgA/111.0.1661.59",
	"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2866.69 Safari/537.36",
	"Mozilla/5.0 (iPad; CPU OS 16_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/80.0.3987.95 Mobile/15E148 Safari/604.1",
	"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0); 360Spider",
	"Dalvik/2.1.0 (Linux; U; Android 7.0; BRAVIA 4K GB Build/NRD91N.S42)",
	"Mozilla/5.0 (Linux; U; Android 4.2.2; en-us; AFTB Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
}

func NewConfig(configPath string) (*Config, error) {
	// Create config structure
	config := &Config{}

	// Open config file
	file, err := os.Open(configPath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Init new YAML decode
	d := yaml.NewDecoder(file)

	// Start YAML decoding from file
	if err := d.Decode(&config); err != nil {
		return nil, err
	}

	return config, nil
}

func ValidateConfigPath(path string) error {
	s, err := os.Stat(path)
	if err != nil {
		return err
	}
	if s.IsDir() {
		return fmt.Errorf("'%s' is a directory, not a normal file", path)
	}
	return nil
}

func ParseFlags() (string, bool, error) {
	var configPath string
	flag.StringVar(&configPath, "config", "./config.yml", "path to config file")
	configDebug := flag.Bool("debug", false, "sets log level to debug")
	flag.Parse()

	if err := ValidateConfigPath(configPath); err != nil {
		return "", true, err
	}

	return configPath, *configDebug, nil
}

func scrape(id int, conf *Config) {

	var db *sql.DB
	var err error
	var url string
	var code string
	var timestamp time.Time
	var volume string
	var value float64

	type Message struct {
		Code      string    `json:"code"`
		Timestamp time.Time `json:"timestamp"`
		Value     float64   `json:"value"`
		Volume    string    `json:"volume"`
	}
	log.Info().Msg("Start worker " + strconv.Itoa(id))
	// Rabbimq connection
	rmqServer := "amqp://" + conf.Rabbitmq.User + ":" + conf.Rabbitmq.Password + "@" + conf.Rabbitmq.Host + ":" + conf.Rabbitmq.Port + conf.Rabbitmq.Vhost
	rmq, err := amqp.Dial(rmqServer)

	if err != nil {
		log.Error().Msg("Error to connect to Rabbitmq")
	}

	log.Info().Msg("Connected to Rabbitmq with worker" + strconv.Itoa(id))
	defer rmq.Close()
	ch, err := rmq.Channel()
	if err != nil {
		log.Error().Msg("Error to open a Channel with Rabbitmq")
	}
	defer ch.Close()

	queue, err := ch.QueueDeclare(
		conf.Rabbitmq.Queue, // Nom de la file
		true,                // Durabilité
		false,               // Suppression automatique lorsque tous les consommateurs se déconnectent
		false,               // Exclusivité
		false,               // Pas d'arguments supplémentaires
		nil,
	)
	if err != nil {
		log.Error().Msg("Error to create a queue with Rabbitmq")
	}

	// Postgres connection
	pgServer := "postgres://" + conf.Postgres.User + ":" + conf.Postgres.Password + "@" + conf.Postgres.Host + "/" + conf.Postgres.Database + "?sslmode=disable"

	db, err = sql.Open("postgres", pgServer)
	if err != nil {
		log.Error().Msg("Error to open a connection with Postgresql")
	}
	if err = db.Ping(); err != nil {
		panic(err)
	}
	log.Info().Msg("Connected to Postgresql with worker " + strconv.Itoa(id))

	for true {

		sqlSelect := "SELECT code FROM cryptos_ref where scrape_begin is null OR scrape_begin < scrape_end AND (now() - scrape_begin) > interval '10' second ORDER BY scrape_begin ASC NULLS FIRST LIMIT 1;"
		rows, err := db.Query(sqlSelect)
		if err != nil {
			log.Error().Msg("Error with the sql query SELECT cryptos")
		}

		for rows.Next() {
			rows.Scan(&code)
		}

		// Begin scrape
		log.Debug().Msg(code + " - Scrape begin")

		db.Exec(`UPDATE cryptos_ref SET scrape_begin = $1 WHERE code = $2`, time.Now(), code)
		log.Debug().Msg(code + " - Scrape begin updated in database")

		// Instantiate default collector
		c := colly.NewCollector(
			colly.AllowURLRevisit(),
		)
		c.Limit(&colly.LimitRule{
			DomainGlob:  "*httpbin.*",
			RandomDelay: 3 * time.Second,
		})

		rand.Seed(time.Now().UnixNano())
		randIdx := rand.Intn(len(userAgent))
		vUserAgent := userAgent[randIdx]

		c.OnRequest(func(r *colly.Request) {
			r.Headers.Set("User-Agent", vUserAgent)
			//r.Headers.Set("User-Agent", "1 Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148")
		})

		c.OnHTML("fin-streamer", func(e *colly.HTMLElement) {
			if e.Attr("data-test") == "qsp-price" && e.Attr("data-field") == "regularMarketPrice" {
				value, _ = strconv.ParseFloat(e.Attr("value"), 64)
			}
		})

		c.OnHTML("td", func(e *colly.HTMLElement) {
			if e.Attr("data-test") == "MARKET_CAP-value" {
				volume = e.Text
			}
		})

		c.OnError(func(_ *colly.Response, err error) {
			fmt.Println("Something went wrong:", err)
		})

		log.Debug().Msg(code + " - Url parsing begin")
		url = "https://fr.finance.yahoo.com/quote/" + code
		c.Visit(url)
		time.Sleep(500 * time.Millisecond)
		c.Wait()

		fmt.Println("## Start")
		fmt.Println(code)
		fmt.Println(value)
		fmt.Println(url)

		log.Debug().Msg(code + " - Url parse ended")

		timestamp = time.Now()

		message := Message{
			Code:      code,
			Timestamp: timestamp,
			Value:     value,
			Volume:    volume,
		}

		jsonData, err := json.Marshal(message)
		if err != nil {
			log.Error().Msg(code + " - Message not ready")
		}

		log.Debug().Msg(code + " - Message ready")

		err = ch.Publish(
			"",         // Échange (utiliser une chaîne vide pour publier directement à la file)
			queue.Name, // Nom de la file
			false,      // Attendre une confirmation du courtier
			false,      // Rendre le message persistant
			amqp.Publishing{
				ContentType: "application/json", // Spécifier le type de contenu en tant que JSON
				Body:        jsonData,           // Utiliser les données JSON encodées
			},
		)
		if err != nil {
			log.Error().Msg(code + " - Message not published")
		}

		log.Debug().Msg(code + " - Send to rabbitmq")

		db.Exec(`UPDATE cryptos_ref SET scrape_end = $1 WHERE code = $2`, time.Now(), code)
		log.Debug().Msg(code + " - Scrape end updated in database")
		log.Debug().Msg(code + " - Scrape end")
	}

}

func main() {
	var wg sync.WaitGroup

	// Check flag config config & log level
	cfgPath, cfgDebug, err := ParseFlags()
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	if cfgDebug {
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	}

	if err != nil {
		log.Error().Msg("Error in configuration")
	}

	// define new config
	cfg, err := NewConfig(cfgPath)
	if err != nil {
		log.Error().Msg("Error in configuration")
	}

	for i := 1; i <= 2; i++ {
		wg.Add(1)
		i := i

		go func() {
			defer wg.Done()
			scrape(i, cfg)
		}()
		// wait 10s before to start another worker
		time.Sleep(10000 * time.Millisecond)
	}
	wg.Wait()
}
