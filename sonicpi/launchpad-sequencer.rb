# Blip Rhythm

# Coded by Sam Aaron

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

state = {
}


teal = 37
pink = 56


offsets.each do |offset|
  if dice(2) == 2
    midi_note_on offset, teal, port: launchpad_out, channel: static_color
    state[offset] = true
  else
    midi_note_off offset, port: launchpad_out, channel: static_color
    state[offset] = false
  end
end


note_length = 0.15

live_loop :clock do
  use_real_time
  
  offsets.each do |offset|
    puts "clock:aiiiiiiiiiiiiiiii"
    
    note = offset
    
    midi_note_on note, pink, port: launchpad_out, channel: static_color
    
    if state[note]
      midi_note_on :C2, port: midi_out, channel: 1
    end
    
    sleep note_length
    midi_note_off note, pink, port: launchpad_out, channel: static_color
    
    if state[note]
      
      # end the last note
      midi_note_off :C2, port: midi_out, channel: 1
      # set it back to the toggled color
      midi_note_on note, teal, port: launchpad_out, channel: static_color
    end
    sleep note_length
  end
end

live_loop :toggles do
  use_real_time
  note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
  state[note] = !state[note]
  
  if state[note]
    midi_note_on note, teal, port: launchpad_out, channel: static_color
  else
    midi_note_off note, port: launchpad_out, channel: static_color
  end
  # sleep a little to prevent key up from triggering it again
  sleep note_length
end


live_loop :kick do
  use_real_time
  puts "aiiiiiiiiiiiiiiii"
  note, velocity = sync "/midi:#{midi_out}:1:1/note_on"
  puts note
  puts velocity
  sample :drum_heavy_kick, amp: 0.5
end

##| live_loop :dynamic_kick do
##|   use_real_time
##|   note, velocity = sync "/midi:launchpad_x_lpx_midi_out:4:1/note_on"
##|   sample :drum_heavy_kick, amp: 0.5
##| end
