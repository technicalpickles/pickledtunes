# Blip Rhythm

# Coded by Sam Aaron

sps = "/Users/technicalpickles/Dropbox/Music Making/Sample Packs"
br = "#{sps}/The Synth Sounds of Blade Runner - Reverb Sample Pack"
brp = "#{br}/Percussion"
brs = "#{br}/SYNTH SOUND"
brfx = "#{br}/FX"


load_samples [:drum_heavy_kick, :elec_plip, :elec_blip]
use_bpm 100

static_color = 1
flashing_color = 2
pulsing_color = 3

launchpad_out = "launchpad_x_lpx_midi_in"

midi_note_off 81, 56, port: launchpad_out

offsets =[
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

note_length = 0.25
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


offsets.each do |offset|
  instruments.each do |instrument|
    step_off(instrument, offset + instrument)
    ##| if dice(2) == 2
    ##|   step_on(instrument, offset+instrument)
    ##| else
    ##|   step_off(instrument, offset+instrument)
    ##| end
  end
  
end

define :pink_on do |note|
  
  midi_note_on note, pink, port: launchpad_out, channel: static_color
  puts "pink on #{note}"
end

define :pink_off do |note|
  midi_note_off note, pink, port: launchpad_out, channel: static_color
end


live_loop :clock do
  use_real_time
  
  offsets.each do |offset|
    
    instruments.each do |instrument|
      note = offset + instrument
      pink_on(note)
      
      if play_step?(instrument, note)
        midi_note_on note, port: midi_out, channel: 1
      end
      
    end
    
    sleep note_length
    
    instruments.each do |instrument|
      note = offset + instrument
      pink_off(note)
      
      if play_step?(instrument, note)
        # end the last note
        midi_note_off note, port: midi_out, channel: 1
        # set it back to the toggled color
        midi_note_on note, teal, port: launchpad_out, channel: static_color
      end
    end
    
    sleep note_length
  end
end

live_loop :toggles do
  use_real_time
  note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
  instrument = note_to_instrument(note)
  puts "instrument #{instrument}"
  toggle_step(instrument, note)
  
  # sleep a little to prevent key up from triggering it again
  sleep note_length
end


live_loop :instrument do
  use_real_time
  note, velocity = sync "/midi:#{midi_out}:1:1/note_on"
  instrument = note_to_instrument(note)
  
  sample_step(instrument)
end

define :note_to_instrument do |note|
  # note 11, 21, etc are instrument '0'
  # note 12, 22, etc are instrument '1'
  instrument = note % 10 - 1
end

define :sample_step do |instrument|
  case instrument
  when 0
    sample :drum_heavy_kick, amp: 0.5
  when 1
    sample :elec_plip, amp: 0.5
  when 2
    sample :elec_blip
  when 3
    use_synth :fm
    play :c2, attack: 0, release: 0.25
  when 4
    sample :drum_cymbal_open, attack: 0.1, sustain: 0.1, release: 0.1 # 0.5
  when 5
    sample brp, "STOMP 2", sustain: 0, release: 1
    
  end
end

##| live_loop :dynamic_kick do
##|   use_real_time
##|   note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
##|   sample :drum_heavy_kick, amp: 0.5
##| end
