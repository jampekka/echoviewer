import { useState, createElement, Fragment, useRef, useMemo, useEffect } from 'react'
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
    'balloon.wav':
        title: "Balloon pop"
        description: "Balloon pop used for measuring acoustics."
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
        gain: 0.5
    'pirunkirkko_fake.wav':
        title: "Pirunkirkko"
        description: "A cave at Koli national park, Finland."
        gain: 0.05
    'silence.wav':
        title: "Anechoic Room",
        description: "No added acoustics."
        gain: 0.0

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

import { useWavesurfer } from '@wavesurfer/react'
import Timeline from 'wavesurfer.js/dist/plugins/timeline.esm.js'


SoundSamplePlayer = $component ({sound_sample, impulse_response, audioContext}) ->
    # TODO: Keep playing after sample change

    audio_graph = useMemo (->
        input = audioContext.createGain()
        output = audioContext.destination

        convolver_gain = audioContext.createGain()
        dry_gain = audioContext.createGain()

        dry_gain.gain.value = 0.2
        convolver_gain.gain.value = 0.1

        convolver = null
        convolver_gain.connect(output)
        input.connect(dry_gain).connect(output)
        
        {input, convolver, convolver_gain, dry_gain}
    ), []

    {sample_audio, sample_node} = useMemo (->
        sample_audio = new Audio()
        sample_audio.src = sound_sample.src
        #sample_audio.loop = true

        if sample_node
            sample_node.disconnect()
        sample_node = audioContext.createMediaElementSource sample_audio
        console.log "Connecting sample", sample_node
        sample_node.connect audio_graph.input

        {sample_audio, sample_node}
    ), [sound_sample]

    # TODO: We now get the .wav twice. Figure out
    # how to pass only the buffer to wavesurfer
    {ir_audio} = useMemo (->
        ir_audio = new Audio()
        ir_audio.src = impulse_response.src

        {ir_audio}
    ), [impulse_response]

    useEffect (->
        if audio_graph.convolver
                audio_graph.convolver.disconnect()
        do ->
            tmp = await fetch impulse_response.src
            tmp = await tmp.arrayBuffer();
            tmp = await audioContext.decodeAudioData tmp
            
            convolver = audioContext.createConvolver()
            convolver.buffer = tmp

            audio_graph.convolver = convolver
            audio_graph.convolver_gain.gain.value = impulse_response.gain ? 1.0
            audio_graph.input.connect(convolver).connect audio_graph.convolver_gain

        return ->
            console.log "Uneffect"
    ), [impulse_response]

    #console.log sample_audio

    sample_surfer_ref = useRef()
    ir_surfer_ref = useRef()

    sample_surfer = useWavesurfer
        container: sample_surfer_ref
        media: sample_audio
        #url: sound_sample.src


    ir_surfer = useWavesurfer
        container: ir_surfer_ref
        media: ir_audio
        interact: false

    icon = if sample_surfer.isPlaying then 'mdi:pause' else 'mdi:play'
    
    toggle_play = ->
        sample_surfer.wavesurfer.playPause()

    toggle_acoustics = ->

    sample_el = @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            @div class: 'flex-none w-10',
                @label for: 'sample_drawer', class: 'btn btn-ghost btn-lg btn-square',
                    @ Icon, icon: 'majesticons:menu', class: 'text-2xl'
            @div class: 'flex-1 card w-full bg-base-100 shadow',
                @div class: 'card-body',
                    @h2 class: 'card-title', "Sound sample: #{sound_sample.title}"
                    @p {}, sound_sample.description
                    @div class: 'flex flex-row items-center gap-4',
                        @button class: "btn btn-circle btn-lg text-4xl", onClick: toggle_play,
                            @ Icon, icon: icon
                        @div class: "w-full join-item", ref: sample_surfer_ref
            @div class: 'flex-none w-10'
    
    ir_el = @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            @div class: 'flex-none w-10'
            @div class: 'flex-1 card w-full bg-base-100 shadow',
                @div class: 'card-body',
                    @h2 class: 'card-title', "Acoustics: #{impulse_response.title}"
                    @p {}, impulse_response.description
                    @div class: 'flex flex-row items-center gap-4',
                        @button class: "btn btn-circle btn-lg text-4xl invisible", onClick: toggle_acoustics,
                            @ Icon, icon: icon
                        @div class: "w-full join-item", ref: ir_surfer_ref
            @div class: 'flex-none w-10',
                @label for: 'impulse_response_drawer', class: 'btn btn-ghost btn-lg btn-square',
                    @ Icon, icon: 'majesticons:menu', class: 'text-2xl'
    
    @ Fragment, {}, sample_el, ir_el

App = $component ->
    # TODO: Get from url params
    [sound_sample_id, set_sound_sample_id] = useState Object.keys(sound_samples)[0]
    [impulse_response_id, set_impulse_response_id] = useState Object.keys(impulse_responses)[0]

    sound_sample = sound_samples[sound_sample_id]
    impulse_response = impulse_responses[impulse_response_id]

    audioContext = useMemo (-> new AudioContext()), []

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

    # TODO: Refactor the drawer. Or get rid of it
    right_drawer = @div class: 'drawer drawer-end',
        @style {}, '.drawer-side {z-index: 1000;}'
        @input id: 'impulse_response_drawer', type: 'checkbox', class: 'drawer-toggle'
        @div class: 'drawer-side',
            @label for: 'impulse_response_drawer', 'aria-label': 'close sidebar', class: 'drawer-overlay'
            @ul class: "menu p4 min-h-full bg-base-200 text-base-content",

            entries impulse_responses, (id, sample) =>
                onClick = ->
                        document.querySelector("#impulse_response_drawer").checked = false
                checked = sound_sample_id == id
                select = (e) ->
                            set_impulse_response_id e.target.value
                @li key: id, onClick: onClick,
                    @input
                        class: 'hidden',
                        type: 'radio', id: id, value: id, name: 'impulse_response_id',
                        checked: checked, onChange: select
                    @label for: id, class: (if checked then 'active'),
                        @ SoundSampleCard, sample: sample

    # Handle fragment in e?
    @ Fragment, {},
        left_drawer,
        right_drawer
        @ SoundSamplePlayer, {sound_sample, impulse_response, audioContext}

createRoot(document.getElementById 'app' ).render e App