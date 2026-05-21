<script setup>
import { reactive, ref } from "vue";

const props = defineProps({
  endpoint: { type: String, required: true },
});

const ARTEN = ["FESTANSTELLUNG", "AZUBI", "MINIJOB", "WERKSTUDENT", "PRAKTIKUM"];

const form = reactive({
  titel: "",
  beschreibung: "",
  art: "FESTANSTELLUNG",
});

const submitting = ref(false);
const success = ref(null);
const error = ref(null);

async function submit() {
  submitting.value = true;
  success.value = null;
  error.value = null;

  // Status wird absichtlich NICHT gesendet - das Backend setzt
  // gemaess Geschaeftsregel immer ENTWURF.
  const payload = {
    titel: form.titel.trim(),
    beschreibung: form.beschreibung.trim() || null,
    art: form.art,
  };

  try {
    const res = await fetch(props.endpoint, {
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
        "Pruefe, ob das Backend laeuft und die CORS-Header gesetzt sind.",
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
  success.value = null;
  error.value = null;
}
</script>

<template>
  <form class="card" @submit.prevent="submit">
    <h2>Stellenangebot anlegen</h2>
    <p class="muted" style="margin-top: 0.25rem;">
      Endpoint: <span class="endpoint-preview">{{ endpoint }}</span>
      <br />
      <em>Neue Stellen starten gemaess Geschaeftsregel immer als <code>ENTWURF</code>.</em>
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
      <strong>Stelle angelegt.</strong>
      <ul>
        <li>ID: <code>{{ success.id }}</code></li>
        <li>Titel: <code>{{ success.titel }}</code></li>
        <li>Art: <code>{{ success.art }}</code></li>
        <li>Status: <code>{{ success.status }}</code></li>
      </ul>
    </div>

    <div v-if="error" class="alert alert-error">
      <strong>Fehler {{ error.status || "" }}:</strong> {{ error.message }}
      <ul v-if="Array.isArray(error.details) && error.details.length">
        <li v-for="(d, i) in error.details" :key="i">{{ d }}</li>
      </ul>
    </div>
  </form>
</template>
