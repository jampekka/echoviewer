import { useState, createElement, Fragment} from 'react'
import { createRoot } from 'react-dom/client';
import { Icon } from '@iconify/react';

entries = (o, f) -> Object.entries(o).map (kv) -> f kv...

#e = createElement
# TODO: Get rid of all react magic (style, camelCasing etc)

create_element = (el, options, children...) ->
    # TODO: Optional options?
    # TODO: List to Fragment
    # Rename keywords to unhack the react hacks
    options ?= {}
    options = Object.fromEntries entries options, (k, v) ->
                k = {class: 'className', for: 'htmlFor'}[k] ? k
                [k, v]
    createElement el, options, children...

e = new Proxy create_element,
    get: (target, prop) -> (options={}, children...) ->
            target prop, options, children...

# TODO Create element automatically?
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

SoundSampleCard = $component ({sample}) ->
    @div class: 'w-96 image-full',
        @div class: 'card-body',
            @h2 class: 'card-title', sample.title
            @p {}, sample.description

SoundSamplePlayer = $component ({sound_sample, impulse_response, audioContext}) ->
    # TODO: Keep playing after sample change
    sample_audio_el = @audio
        class: 'w-full'
        src: sound_sample.src
        controls: true
        loop: true

    console.log "Here"    

    @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            @div class: 'flex-none w-10',
                @label for: 'sample_drawer', class: 'btn btn-ghost-btn-square',
                    @ Icon, icon: 'majesticons:menu', class: 'text-2xl'
            @div class: 'flex-1 card w-full bg-base-100 shadow',
                @div class: 'card-body',
                    @h2 class: 'card-title', "Sound sample: #{sound_sample.title}"
                    @p {}, sound_sample.description
                    sample_audio_el
        @div class: 'flex-none w-10'

App = $component ->
    # TODO: Get from url params
    [sound_sample_id, set_sound_sample_id] = useState Object.keys(sound_samples)[0]
    [impulse_response_id, set_impulse_response_id] = useState Object.keys(impulse_responses)[0]

    sound_sample = sound_samples[sound_sample_id]
    impulse_response = impulse_responses[sound_sample_id]

    audioContext = new AudioContext()

    left_drawer = @div class: 'drawer',
        @style {}, '.drawer-side {z-index: 1000;}'
        @input id: 'sample_drawer', type: 'checkbox', class: 'drawer-toggle'
        @div class: 'drawer-side',
            @label for: 'sample_drawer', 'aria-label': 'close sidebar', class: 'drawer-overlay'
            @ul class: "menu p4 min-h-full bg-base-200 text-base-content",

            entries sound_samples, (id, sample) =>

                onClick = ->
                        document.querySelector("#sample_drawer").checked = false
                checked = sound_sample_id == id
                select = (e) ->
                            set_sound_sample_id e.target.value
                @li key: id, onClick: onClick,
                    @input
                        class: 'hidden',
                        type: 'radio', id: id, value: id, name: 'sound_sample_id',
                        checked: checked, onChange: select
                    @label for: id, class: (if checked then 'active'),
                        @ SoundSampleCard, sample: sample

    # Handle fragment in e?
    @ Fragment, {},
        left_drawer
        @ SoundSamplePlayer, {sound_sample, impulse_response, audioContext}

createRoot(document.getElementById 'app' ).render e App