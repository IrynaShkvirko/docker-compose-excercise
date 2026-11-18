package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Note struct {
	ID    primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Title string             `json:"title" bson:"title"`
	Body  string             `json:"body" bson:"body"`
}

var coll *mongo.Collection

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func listNotes(w http.ResponseWriter, r *http.Request) {
	cur, err := coll.Find(r.Context(), bson.M{})
	if err != nil {
		writeJSON(w, 500, map[string]string{"error": err.Error()})
		return
	}
	notes := []Note{}
	if err := cur.All(r.Context(), &notes); err != nil {
		writeJSON(w, 500, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, 200, notes)
}

func createNote(w http.ResponseWriter, r *http.Request) {
	var n Note
	if err := json.NewDecoder(r.Body).Decode(&n); err != nil || n.Title == "" {
		writeJSON(w, 400, map[string]string{"error": "title required"})
		return
	}
	res, err := coll.InsertOne(r.Context(), n)
	if err != nil {
		writeJSON(w, 500, map[string]string{"error": err.Error()})
		return
	}
	n.ID = res.InsertedID.(primitive.ObjectID)
	writeJSON(w, 201, n)
}

func deleteNote(w http.ResponseWriter, r *http.Request) {
	id, err := primitive.ObjectIDFromHex(r.PathValue("id"))
	if err != nil {
		writeJSON(w, 400, map[string]string{"error": "bad id"})
		return
	}
	res, err := coll.DeleteOne(r.Context(), bson.M{"_id": id})
	if err != nil || res.DeletedCount == 0 {
		writeJSON(w, 404, map[string]string{"error": "not found"})
		return
	}
	w.WriteHeader(204)
}

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	client, err := mongo.Connect(ctx, options.Client().ApplyURI(env("MONGO_URI", "mongodb://localhost:27017")))
	if err != nil {
		log.Fatal(err)
	}
	coll = client.Database(env("MONGO_DB", "notes")).Collection("notes")

	mux := http.NewServeMux()
	mux.HandleFunc("GET /notes", listNotes)
	mux.HandleFunc("POST /notes", createNote)
	mux.HandleFunc("DELETE /notes/{id}", deleteNote)
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		if err := client.Ping(r.Context(), nil); err != nil {
			writeJSON(w, 503, map[string]string{"status": "down"})
			return
		}
		writeJSON(w, 200, map[string]string{"status": "ok"})
	})

	addr := ":" + env("PORT", "8080")
	log.Println("listening on", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
