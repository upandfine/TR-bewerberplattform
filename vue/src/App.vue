<script setup>
import { computed, reactive, ref } from "vue";
import StellenangebotForm from "./StellenangebotForm.vue";

const BACKENDS = {
  php: { label: "PHP / Apache", defaultBase: "http://localhost:8080", path: "/api.php" },
  python: { label: "Python / Flask", defaultBase: "http://localhost:8001", path: "/api/bewerbungen" },
  node: { label: "Node.js / Express", defaultBase: "http://localhost:3000", path: "/api/bewerbungen" },
  dotnet: { label: ".NET / ASP.NET Core", defaultBase: "http://localhost:8082", path: "/api/bewerbungen" },
};

const view = ref("bewerbung");
const backendTyp = ref("php");
const basisUrl = ref(BACKENDS.php.defaultBase);

function onBackendChange() {
  basisUrl.value = BACKENDS[backendTyp.value].defaultBase;
}

const endpoint = computed(() => {
  const base = basisUrl.value.replace(/\/+$/, "");
  return base + BACKENDS[backendTyp.value].path;
});

const form = reactive({
  vorname: "",
  nachname: "",
  email: "",
  telefon: "",
  stelle_id: 1,
  bemerkung: "",
});

const submitting = ref(false);
const success = ref(null);
const error = ref(null);

async function submit() {
  submitting.value = true;
  success.value = null;
  error.value = null;

  const payload = {
    vorname: form.vorname.trim(),
    nachname: form.nachname.trim(),
    email: form.email.trim(),
    telefon: form.telefon.trim() || null,
    stelle_id: Number(form.stelle_id),
    bemerkung: form.bemerkung.trim() || null,
  };

  try {
    const res = await fetch(endpoint.value, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const text = await res.text();
    let body = null;
    try {
      body = text ? JSON.parse(text) : null;
    } catch {
      body = { fehler: text || `HTTP ${res.status}` };
    }

    if (!res.ok) {
      error.value = {
        status: res.status,
        message: body?.fehler || `Anfrage fehlgeschlagen (HTTP ${res.status}).`,
        details: body?.details || null,
      };
      return;
    }

    success.value = body;
  } catch (e) {
    error.value = {
      status: 0,
      message:
        "Netzwerkfehler oder CORS-Problem. " +
        "Prüfe, ob das Backend läuft und die CORS-Header gesetzt sind.",
      details: [String(e?.message || e)],
    };
  } finally {
    submitting.value = false;
  }
}

function reset() {
  form.vorname = "";
  form.nachname = "";
  form.email = "";
  form.telefon = "";
  form.stelle_id = 1;
  form.bemerkung = "";
  success.value = null;
  error.value = null;
}
</script>

<template>
  <main class="shell">
    <h1>Bewerberplattform</h1>
    <p class="subtitle">
      Test-Frontend für die vier Backend-Beispiele (PHP, Python, Node, .NET).
    </p>

    <section class="card">
      <h2>Backend</h2>
      <div class="grid grid-2">
        <label>
          <span class="req">Backend-Typ</span>
          <select v-model="backendTyp" @change="onBackendChange">
            <option v-for="(b, key) in BACKENDS" :key="key" :value="key">
              {{ b.label }}
            </option>
          </select>
        </label>

        <label>
          <span class="req">Basis-URL</span>
          <input
            v-model="basisUrl"
            type="url"
            placeholder="http://localhost:8080"
            spellcheck="false"
          />
        </label>
      </div>
      <p class="muted" style="margin-top: 0.75rem;">
        Bewerbungs-Endpoint: <span class="endpoint-preview">{{ endpoint }}</span>
      </p>
    </section>

    <nav class="tabs" role="tablist">
      <button
        type="button"
        role="tab"
        :aria-selected="view === 'bewerbung'"
        :class="['tab', { active: view === 'bewerbung' }]"
        @click="view = 'bewerbung'"
      >
        Bewerbung
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="view === 'stelle'"
        :class="['tab', { active: view === 'stelle' }]"
        @click="view = 'stelle'"
      >
        Stellenangebot
      </button>
    </nav>

    <StellenangebotForm v-if="view === 'stelle'" :basis-url="basisUrl" />

    <form v-if="view === 'bewerbung'" class="card" @submit.prevent="submit">
      <h2>Daten</h2>
      <div class="grid grid-2">
        <label>
          <span class="req">Vorname</span>
          <input v-model="form.vorname" required maxlength="60" />
        </label>
        <label>
          <span class="req">Nachname</span>
          <input v-model="form.nachname" required maxlength="60" />
        </label>
        <label>
          <span class="req">E-Mail</span>
          <input v-model="form.email" type="email" required maxlength="120" />
        </label>
        <label>
          <span>Telefon</span>
          <input v-model="form.telefon" type="tel" maxlength="30" />
        </label>
        <label>
          <span class="req">Stellen-ID</span>
          <input v-model.number="form.stelle_id" type="number" min="1" required />
        </label>
      </div>

      <label style="margin-top: 0.85rem;">
        <span>Bemerkung</span>
        <textarea v-model="form.bemerkung" maxlength="500" />
      </label>

      <div class="row" style="margin-top: 1.25rem;">
        <button type="submit" :disabled="submitting">
          {{ submitting ? "Sende…" : "Bewerbung absenden" }}
        </button>
        <button type="button" @click="reset" style="background: transparent; color: var(--muted); border-color: var(--border);">
          Zurücksetzen
        </button>
      </div>

      <div v-if="success" class="alert alert-success">
        <strong>Bewerbung eingegangen.</strong>
        <ul>
          <li>Vorgangsnummer: <code>{{ success.vorgangs_nr }}</code></li>
          <li>Bewerbung-ID: <code>{{ success.bewerbung_id }}</code></li>
          <li>Bewerber-ID: <code>{{ success.bewerber_id }}</code></li>
        </ul>
      </div>

      <div v-if="error" class="alert alert-error">
        <strong>Fehler {{ error.status || "" }}:</strong> {{ error.message }}
        <ul v-if="Array.isArray(error.details) && error.details.length">
          <li v-for="(d, i) in error.details" :key="i">{{ d }}</li>
        </ul>
      </div>
    </form>
  </main>
</template>
