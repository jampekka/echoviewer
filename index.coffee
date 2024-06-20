import { useState, createElement, Fragment} from 'react'
import { createRoot } from 'react-dom/client';

entries = (o, f) -> Object.entries(o).map (kv) -> f kv...

#e = createElement
e = new Proxy createElement,
    get: (target, prop, receiver) -> (options={}, children...) ->
            # Rename keywords to hack the react hack
            options = Object.fromEntries entries options, (k, v) ->
                k = {class: 'className', for: 'htmlFor'}[k] ? k
                [k, v]
            target prop, options, children...

$component = (f) -> f.bind e

sound_samples =
    'classical_singing.wav':
        title: "Classical singing"
        description: "Some classical-style singing (TODO DESCRIPTION)"
    'sine_sweep.wav':
        title: "Sine sweep",
        description: "A sine sweep used for measuring acoustics."

###
    'karelian_joik_classic.wav': {
        title: "A Karelian Joik",
        description: "A Karelian style joik (TODO DESCRIPTION)"
    },

    'impulse.wav': {
        title: "Single impulse",
        description: "Only the acoustics."
    },
###

impulse_responses =
    'siliavuori.wav':
        title: "Siliävuori"
        description: "Siliävuori rock cliff, Finland."
    'pirunkirkko_fake.wav':
        title: "Pirunkirkko"
        description: "A cave at Koli national park, Finland."
    '':
        title: "Anechoic Room",
        description: "No added acoustics."

###
    'astuvansalmi.wav': {
        title: "Astuvansalmi",
        description: "Astuvansalmi rock cliff at ???, Finland."
    },
###

entries sound_samples,  (k, v) ->
    v.id ?= k
    v.src ?= "./sound_samples/"+k

entries impulse_responses, (k, v) ->
    v.id ?= k
    v.src ?= "./impulse_responses/"+k

SoundSampleCard = -> e.h1 "Todo"

SoundSamplePlayer = $component ({sound_sample, impulse_response, audioContext}) ->
    @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            sound_sample.title

App = $component ->
    # TODO: Get from url params
    [sound_sample_id, set_sound_sample_id] = useState Object.keys(sound_samples)[0]
    [impulse_response_id, set_impulse_response_id] = useState Object.keys(impulse_responses)[0]

    sound_sample = sound_samples[sound_sample_id]
    impulse_response = impulse_responses[sound_sample_id]

    audioContext = new AudioContext()

    left_drawer = @div class: 'drawer',
        @input id: 'sample_drawer', type: 'checkbox', class: 'drawer-toggle'
        @div class: 'drawer-side',
            @label for: 'sample_drawer', 'aria-label': 'close sidebar', class: 'drawer-overlay'
            @ul className: "menu p4 min-h-full bg-base-200 text-base-content",
            entries sound_samples, (id, sample) =>
                @li key: id,
                    @input type: 'radio', id: id, value: id, name: 'sound_sample_id'
                    @label for: 'id',
                        id.title

    # Handle fragment in e?
    @ Fragment, {},
        left_drawer
        @ SoundSamplePlayer, {sound_sample, impulse_response, audioContext}

    ###
    <div class="drawer">
        <input id="sample_drawer" type="checkbox" class="drawer-toggle" />
        <div class="drawer-side">
            <label for="sample_drawer" aria-label="close sidebar" class="drawer-overlay"></label> 
            <ul class="menu p-4 min-h-full bg-base-200 text-base-content">
                {Object.entries(sound_samples).map (id, sample) ->
                <li>
                    <input type="radio" id="id" name="sound_sample_id" value="id" v-model="sound_sample_id" />
                    <label for="id">
                        <SoundSampleCard sample="sample" />
                    </label>
                </li>
                }
            </ul>
        </div>
    </div>
    e 'div', {class: 'drawer'},
        e 'input
    ###

createRoot(document.getElementById 'app' ).render e App