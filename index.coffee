import { useState, createElement, Fragment, useRef, useMemo, useEffect } from 'react'
import { createRoot } from 'react-dom/client'
import { Icon } from '@iconify/react'

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

impulse_responses =
    'siliavuori.wav':
        title: "Siliävuori"
        description: "Siliävuori rock cliff, Finland."
        dry: 1.0
    'varikallio-rockart-44m-summer-pop.wav':
        title: "Värikallio"
        description: "Balloon pop measurement at 44 meters from painting rock. In summer."
        dry: 1.0
    'keltavuori-rockart-44m-summer-pop.wav': {}
    'Kirkhelleren-Norway-cave-concert-setup-summer-pop.wav': {}
    'haukkasaari-rockart2-44m-winter-pop.wav': {}
    'pirunkirkko_fake.wav':
        title: "Pirunkirkko"
        description: "A cave at Koli national park, Finland. Parametric reconstruction of resonance."
        dry: 1.0
        gain: 0.01
    'silence.wav':
        title: "Anechoic Room"
        description: "No added acoustics."
        gain: 0.0
        dry: 1.0

title_from_name = (fname) ->
    fname.split('.')[...-1].join('')
        .split(/[-_]/)
        .map (t) -> t[0].toUpperCase() + t[1...]
        .join(' ')

    


entries impulse_responses, (k, v) ->
    v.id ?= k
    v.src ?= "./impulse_responses/"+k
    v.title ?= title_from_name k

SoundSampleCard = $component ({sample}) ->
    @div class: 'w-96 image-full',
        @div class: 'card-body',
            @h2 class: 'card-title', sample.title
            @p {}, sample.description

import WavesurferPlayer from '@wavesurfer/react'
import { useWavesurfer} from '@wavesurfer/react'
import WaveSurfer from 'wavesurfer.js'
import TimelinePlugin from 'wavesurfer.js/dist/plugins/timeline.esm.js'
import SpectrogramPlugin from 'wavesurfer.js/dist/plugins/spectrogram.esm.js'


SoundSamplePlayer = $component ({sound_sample, impulse_response, audioContext}) ->
    # TODO: Keep playing after sample change
    # TODO: Loading indicators
    audio_graph = useMemo (->
        input = audioContext.createGain()
        output = audioContext.destination

        convolver_gain = audioContext.createGain()
        dry_gain = audioContext.createGain()

        dry_gain.gain.value = 0.0
        convolver_gain.gain.value = 1.0

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
            audio_graph.dry_gain.gain.value = impulse_response.dry ? 0.0
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
        plugins: useMemo (-> [
            TimelinePlugin.create()
            ,
            #SpectrogramPlugin.create()
        ]), []

    ir_surfer = useWavesurfer
        container: ir_surfer_ref
        media: ir_audio
        interact: false
        plugins: useMemo (-> [
            TimelinePlugin.create
                timeInterval: 0.1
                primaryLabelInterval: 1
                #secondaryLabelInterval: 1
            ,
            #SpectrogramPlugin.create
            #    height: 200
        ]), []

    icon = if sample_surfer.isPlaying then 'mdi:pause' else 'mdi:play'
    
    toggle_play = ->
        audioContext.resume()
        sample_surfer.wavesurfer.playPause()

    toggle_acoustics = ->

    sample_el = @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            @div class: 'flex-none',
                @label for: 'sample_drawer', class: 'btn btn-lg btn-ghost btn-square text-4xl',
                    @ Icon, icon: 'mdi:dots-horizontal'
            @div class: 'flex-1 card w-full bg-base-100 shadow',
                @div class: 'card-body',
                    @h2 class: 'card-title', "Sound sample: #{sound_sample.title}"
                    @p {}, sound_sample.description
                    @div class: 'flex flex-row items-center gap-4',
                        @button class: "btn btn-circle btn-lg text-4xl", onClick: toggle_play,
                            @ Icon, icon: icon
                        @div class: "w-full join-item", ref: sample_surfer_ref
            @div class: 'flex-none', @div class: 'btn btn-lg btn-square invisible'
    
    ir_el = @div class: "flex flex-col gap-4",
        @div class: "flex flex-row items-center gap-4",
            @div class: 'flex-none', @div class: 'btn btn-lg btn-square invisible'
            @div class: 'flex-1 card w-full bg-base-100 shadow',
                @div class: 'card-body',
                    @h2 class: 'card-title', "Acoustics: #{impulse_response.title}"
                    @p {}, impulse_response.description
                    @div class: 'flex flex-row items-center gap-4',
                        @button class: "btn btn-circle btn-lg text-4xl invisible", onClick: toggle_acoustics,
                            @ Icon, icon: icon
                        @div class: "w-full join-item", ref: ir_surfer_ref
            @div class: 'flex-none',
                @label for: 'impulse_response_drawer', class: 'btn btn-ghost btn-lg btn-square',
                    @ Icon, icon: 'mdi:dots-horizontal', class: 'text-4xl'
    
    @div class: "flex flex-col gap-4", sample_el, ir_el

App = $component ({sound_samples, impulse_responses}) ->
    # The state is now stored in the url and in useState here.
    # Ugly, but there doesn't seem to be a sane react router

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
                checked = impulse_response_id == id
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

do ->
    get_samples = (path) ->
        # TODO: Use file metadata
        sample_list = await (await fetch "#{path}/index.json").json()
        sample_list.map (fname) ->
            id: fname
            src: "#{path}/#{fname}"
            title: title_from_name fname

    sound_samples = await get_samples "sound_samples"
    
    createRoot(document.getElementById 'app' ).render e App, {sound_samples, impulse_responses}
