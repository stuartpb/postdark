local function rawrpopen(cmd)
  return io.popen(cmd, 'rb') or io.popen(cmd, 'r')
end

-- for every file specified on the command line
for argi = 1, #arg do
  local filename = arg[argi]

  -- init a reverse lookup table for colors-to-indices
  local remap = {}

  -- get ImageMagick to describe the GIF palette
  local idproc = io.popen(('identify -verbose %s'):format(filename), 'r')
  local line

  -- flip through the output until we hit the colormap
  while line ~= '  Colormap:' do line = idproc:read('*l') end

  -- start outputting a script for this palette
  local palfile = io.open(filename:gsub('%.gif$', '-palette.lua'), 'w')
  palfile:write('return {\n')

  -- for every line within the colormap
  -- (ie. until the next line beginning with two or fewer spaces)
  line = idproc:read('*l')
  while line:sub(1,3) == '   ' do

    -- capture the color definition
    local idx, r, g, b, a =
      line:match('^ -(%d+): %( -(%d+), -(%d+), -(%d+), -(%d+)%)')

    -- spit the original color def to the palette script
    palfile:write(('  [%d] = {%d, %d, %d, %d},\n'):format(idx, r, g, b, a))

    -- save the reverse mapping (if this color's not a duplicate)
    local bytes = ('%c%c%c%c'):format(r,g,b,a)
    remap[bytes] = remap[bytes] or idx

    line = idproc:read('*l')
  end

  -- Finish the palette script
  palfile:write('}\n')
  palfile:close()
  idproc:close()

  -- Get the RGBA values of the GIF by pixel to convert to raw indices
  local rawproc = rawrpopen(('convert %s rgba:-'):format(filename))
  local mapout = io.open(filename:gsub('%.gif$', '.map'), 'wb')

  -- for every two pixels of the file
  local colors = rawproc:read(8)
  while colors do

    -- pack the pixels' indices into nibbles in the map
    mapout:write(string.char(
      remap[colors:sub(1, 4)] * 16 +
      remap[colors:sub(5, 8)]))
    -- assuming we have an even number of pixels and fewer than 16 colors
    -- (true of every file in this project we use this script for)

    colors = rawproc:read(8)
  end

  -- Finish the map
  rawproc:close()
  mapout:close()
end
