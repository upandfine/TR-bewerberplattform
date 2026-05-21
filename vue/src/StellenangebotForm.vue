<script setup>
import { computed, reactive, ref } from "vue";

const props = defineProps({
  basisUrl: { type: String, required: true },
});

const ARTEN = ["FESTANSTELLUNG", "AZUBI", "MINIJOB", "WERKSTUDENT", "PRAKTIKUM"];
const STATUS = ["ENTWURF", "VEROEFFENTLICHT", "GESCHLOSSEN", "ARCHIVIERT"];

const pfad = ref("/api/stellenangebote");

const endpoint = computed(() => {
  const base = (props.basisUrl || "").replace(/\/+$/, "");
  const p = pfad.value.startsWith("/") ? pfad.value : "/" + pfad.value;
  return base + p;
});

const form = reactive({
  titel: "",
  beschreibung: "",
  art: "FESTANSTELLUNG",
  status: "ENTWURF",
  veroeffentlicht_am: "",
});

const submitting = ref(false);
const success = ref(null);
const error = ref(null);

function toIsoSeconds(local) {
  if (!local) return null;
  return local.length === 16 ? `${local}:00` : local;
}

async function submit() {
  submitting.value = true;
  success.value = null;
  error.value = null;

  const payload = {
    titel: form.titel.trim(),
    beschreibung: form.beschreibung.trim() || null,
    art: form.art,
    status: form.status,
    veroeffentlicht_am: toIsoSeconds(form.veroeffentlicht_am),
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
        "Prüfe, ob das Backend läuft, der Endpoint-Pfad stimmt und die CORS-Header gesetzt sind.",
      details: [String(e?.message || e)],
    };
  } finally {
    submitting.value = false;
  }
}

function reset() {
  form.titel = "";
  form.beschreibung = "";
  form.art = "FESTANSTELLUNG";
  form.status = "ENTWURF";
  form.veroeffentlicht_am = "";
  success.value = null;
  error.value = null;
}
</script>

<template>
  <form class="card" @submit.prevent="submit">
    <h2>Stellenangebot anlegen</h2>

    <label>
      <span class="req">Endpoint-Pfad</span>
      <input v-model="pfad" placeholder="/api/stellenangebote" spellcheck="false" />
    </label>
    <p class="muted" style="margin-top: 0.5rem;">
      Endpoint: <span class="endpoint-preview">{{ endpoint }}</span>
      <br />
      <em>API-Pfad ist im Backend noch nicht final &mdash; hier später ersetzen.</em>
    </p>

    <div class="grid grid-2" style="margin-top: 1rem;">
      <label>
        <span class="req">Titel</span>
        <input v-model="form.titel" required maxlength="120" />
      </label>

      <label>
        <span class="req">Art</span>
        <select v-model="form.art">
          <option v-for="a in ARTEN" :key="a" :value="a">{{ a }}</option>
        </select>
      </label>

      <label>
        <span class="req">Status</span>
        <select v-model="form.status">
          <option v-for="s in STATUS" :key="s" :value="s">{{ s }}</option>
        </select>
      </label>

      <label>
        <span>Veröffentlicht am</span>
        <input v-model="form.veroeffentlicht_am" type="datetime-local" />
      </label>
    </div>

    <label style="margin-top: 0.85rem;">
      <span>Beschreibung</span>
      <textarea v-model="form.beschreibung" rows="5" />
    </label>

    <div class="row" style="margin-top: 1.25rem;">
      <button type="submit" :disabled="submitting">
        {{ submitting ? "Sende…" : "Stelle anlegen" }}
      </button>
      <button
        type="button"
        @click="reset"
        style="background: transparent; color: var(--muted); border-color: var(--border);"
      >
        Zurücksetzen
      </button>
    </div>

    <div v-if="success" class="alert alert-success">
      <strong>Stellenangebot angelegt.</strong>
      <pre style="margin: 0.5rem 0 0; white-space: pre-wrap;">{{ JSON.stringify(success, null, 2) }}</pre>
    </div>

    <div v-if="error" class="alert alert-error">
      <strong>Fehler {{ error.status || "" }}:</strong> {{ error.message }}
      <ul v-if="Array.isArray(error.details) && error.details.length">
        <li v-for="(d, i) in error.details" :key="i">{{ d }}</li>
      </ul>
    </div>
  </form>
</template>
