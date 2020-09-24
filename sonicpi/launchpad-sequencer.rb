
require "/Users/technicalpickles/hi.rb"




sps = "/Users/technicalpickles/Dropbox/Music Making/Sample Packs"
br = "#{sps}/The Synth Sounds of Blade Runner - Reverb Sample Pack"
brp = "#{br}/Percussion"
brs = "#{br}/SYNTH SOUND"
brfx = "#{br}/FX"


load_samples [:drum_heavy_kick, :elec_plip, :elec_blip]
use_bpm 160

static_color = 1
flashing_color = 2
pulsing_color = 3

launchpad_out = "launchpad_x_lpx_midi_in"

midi_note_off 81, 56, port: launchpad_out

offsets = [
  81,
  71,
  61,
  51,
  41,
  31,
  21,
  11
]

midi_out = "iac_driver_sonic_pi"


teal = 37
pink = 56

beat_length = 1
instruments = (0..7).to_a
state = instruments.map do |instrument|
  {}
end


define :step_on do |instrument, note|
  midi_note_on note, teal, port: launchpad_out, channel: static_color
  state[instrument][note] = true
end

define :play_step? do |instrument, note|
  state[instrument][note]
end


define :step_off do |instrument, note|
  midi_note_off note, port: launchpad_out, channel: static_color
  state[instrument][note] = false
end

define :toggle_step do |instrument, note|
  if !state[instrument][note] # off, now on
    step_on(instrument, note)
  else # on, now off
    step_off(instrument, note)
  end
end


# reset everything
offsets.each_with_index do |offset, y|
  instruments.each_with_index do |instrument, x|
    note = offset + instrument
    puts "#{y},#{x}: note #{note}, off"
    
    step_off(instrument, offset + instrument)
    ##| if dice(2) == 2
    ##|   step_on(instrument, offset+instrument)
    ##| else
    ##|   step_off(instrument, offset+instrument)
    ##| end
  end
end

in_thread do
  loop do
    offsets.each_with_index do |offset, y|
      puts "row #{y}"
      
      cue "tick", offset: offset, y: y
      sleep beat_length
      cue "tock", offset: offset, y: y
    end
  end
end

in_thread do
  loop do
    values = sync "tick"
    puts "tick"
    
    offset = values[:offset]
    x = values[:y]
    
    instruments.each_with_index do |instrument, x|
      note = offset + instrument
      
      midi_note_on note, pink, port: launchpad_out, channel: static_color
      
      if play_step?(instrument, note)
        cue "instrument_#{instrument}"
      end
    end
  end
  
end

in_thread do
  loop do
    
    values = sync "tock"
    puts "tock"
    
    offset = values[:offset]
    y = values[:y]
    instruments.each_with_index do |instrument, x|
      note = offset + instrument
      
      # set it back to the toggled color if it was played
      if play_step?(instrument, note)
        puts "#{y},#{x}: note #{note}, blue"
        midi_note_on note, teal, port: launchpad_out, channel: static_color
      else
        puts "#{y},#{x}: note #{note}, off"
        midi_note_off note, port: launchpad_out, channel: static_color
      end
    end
  end
  
end

live_loop :toggles do
  use_real_time
  note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
  
  # for some reason, release triggers as a note_on with velocity 0?
  if velocity > 0
    instrument = note_to_instrument(note)
    puts "instrument #{instrument}"
    toggle_step(instrument, note)
  end
end

define :note_to_instrument do |note|
  # note 11, 21, etc are instrument '0'
  # note 12, 22, etc are instrument '1'
  instrument = note % 10 - 1
end


live_loop :instrument_0 do
  sync "instrument_0"
  sample :drum_heavy_kick, amp: 0.5
end

live_loop :instrument_3 do
  sync "instrument_1"
  sample :elec_plip, amp: 0.5
end

live_loop :instrument_2 do
  sync "instrument_2"
  sample :elec_blip
end

live_loop :instrument_3 do
  sync "/cue/instrument_3"
  use_synth :fm
  play :c2, attack: 0, release: 0.25
end

live_loop :instrument_4 do
  sync "/cue/instrument_4"
  sample :drum_cymbal_soft, attack: 0.1, sustain: 0.1, release: 0.1 # 0.5
end

live_loop :instrument_5 do
  sync "/cue/instrument_5"
  sample brp, "STOMP 2", sustain: 0, release: 1
end

live_loop :instrument_6 do
  sync "instrument_6"
  
  sample brp, "BLADE RUNNER CABASA (DRY)", start: 0, finish: 0.125
end


##| live_loop :dynamic_kick do
##|   use_real_time
##|   note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
##|   sample :drum_heavy_kick, amp: 0.5
##| end
