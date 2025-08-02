package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/schwartzmx/gremtune"
)

type form struct {
	Type  string   `json:"@type"`
	Value []vertex `json:"@value"`
}
type vertex struct {
	Type  string `json:"@type"`
	Value id     `json:"@value"`
}
type id struct {
	Value value `json:"id"`
}
type value struct {
	Type  string `json:"@type"`
	Value int64  `json:"@value"`
}

const hits = 1000
const workers = 5

func writeJanus(wg *sync.WaitGroup, i int) {
	defer wg.Done()

	errs := make(chan error)
	go func(chan error) {
		err := <-errs
		log.Fatal("Lost connection to the database: " + err.Error())
	}(errs) // Example of connection error handling logic

	dialer := gremtune.NewDialer("ws://janus4:8182/gremlin") // Returns a WebSocket dialer to connect to Gremlin Server
	g, err := gremtune.Dial(dialer, errs)                                                   // Returns a gremtune client to interact with
	if err != nil {
		fmt.Println(err)
	}

	cities := [3]string{"Paris", "Caen", "Moscou"}
	categories := []string{"sportif", "geek", "jardinier", "bricoleur"}

	// Check Cities & Create Cities
	for _, city := range cities {
		//fmt.Println(city)
		_, err := g.Execute("g.V().has('name','" + city + "').next()")

		if err != nil {
			_, err := g.Execute("g.addV('city').property('name', '" + city + "').next()")
			if err != nil {
				fmt.Println(err)
			}
		} else {

		}
	}

	// Create Vertices & Edges

	rand.Seed(time.Now().Unix())
	for i := 0; i < hits; i++ {
		n := rand.Int() % len(cities)
		m := rand.Int() % len(categories)
		prefix := "ID_"
		uid, err := uuid.NewRandom()
		uuid := fmt.Sprintf("%s", uid)
		fmt.Println(uid)
		if err != nil {
			log.Fatal(err)
		}
		id_person := fmt.Sprintf("%s%d", prefix, i)
		fmt.Println(id_person + " -- " + cities[n])

		vcity, _ := g.Execute("g.V().has('name','" + cities[n] + "').next()")
		var datac form
		json.Unmarshal(vcity[0].Result.Data, &datac)
		city := fmt.Sprintf("%d", datac.Value[0].Value.Value.Value)
		if err != nil {
			fmt.Println("Error start")
			fmt.Println(err)
			fmt.Println("Error end")
		}

		if err != nil {
			fmt.Println(err)
			fmt.Println("City not found")
		} else {
			vpeople, err := g.Execute("g.addV('" + categories[m] + "').property('uuid', '" + uuid + "').property('name', '" + id_person + "').property('city', '" + cities[n] + "').next()")
			if err != nil {
				fmt.Println(err)
			} else {
				var datap form
				err := json.Unmarshal(vpeople[0].Result.Data, &datap)
				people := fmt.Sprintf("%d", datap.Value[0].Value.Value.Value)
				if err != nil {
					fmt.Println(err)
				}
				g.Execute("g.V('" + people + "').as('newA').V('" + city + "').as('existingB').addE('live_in').from('newA').to('existingB').next()")
				fmt.Printf("Worker : %d - Person : %s - UID : %s", i, id_person, uuid)
			}
		}
	}
}

func main() {

	var wg sync.WaitGroup

	for i := 0; i < workers; i++ {
		wg.Add(1)
		go writeJanus(&wg, i)
	}

	wg.Wait()
}
