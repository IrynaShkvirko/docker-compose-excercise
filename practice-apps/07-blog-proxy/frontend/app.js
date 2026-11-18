// Calls the API on the same origin: a reverse proxy must route /api/* to the backend.
const postsEl = document.getElementById("posts");

async function loadPosts() {
  const res = await fetch("/api/posts");
  const posts = await res.json();
  postsEl.innerHTML = "";
  for (const p of posts.reverse()) {
    const div = document.createElement("article");
    const h = document.createElement("h2");
    h.textContent = p.title;
    const body = document.createElement("p");
    body.textContent = p.body;
    div.append(h, body);
    postsEl.append(div);
  }
}

document.getElementById("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  await fetch("/api/posts", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title: title.value, body: body.value }),
  });
  e.target.reset();
  loadPosts();
});

loadPosts();
