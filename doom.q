w:read1`:./doom1.wad

s_lump:16
s_linedef:14
s_sidedef:30
s_vertex:4
s_seg:12

/
 * Read and convert bytes
 * @param {bytes} x - data
 * @param {int} y - offset into data
 * @param {int} z - (optional) number of bytes to convert
\
r_int:{0x0 sv reverse x[y + til 4]}
r_short:{0x0 sv reverse x[y + til 2]}
r_ushort:{0x0 sv (0x0000,reverse x[y + til 2])}
r_chars:{"c"$x[y+ til z]}

r_d:`s`us`i`c!(r_short;r_ushort;r_int;r_chars);
r_o:`s`us`i!2 2 4;


ident:"c"$w[til 4];
dirsize:r_int[w;4];
dirloc:r_int[w;8];
dirdata:w dirloc + til dirsize * s_lump

r_dir:{[dd;offset]
 (r_int[dd;offset]; r_int[dd;offset+4]; r_chars[dd;offset+8;8])}[dirdata;]

lumps:r_dir each s_lump * til dirsize;
lumps:`lumploc xasc flip `lumploc`lumpsize`lumpname!flip lumps;

r_linedef:{[dd;offset]
 r_ushort[dd;] each offset + 2 * til 7}

r_linedefs:{[w;start;size]
 x:r_linedef[w;] each start + s_linedef * til size div s_linedef;
 flip `v1`v2`flags`type`sector_tag`rsidedef`lsidedef!flip x}

r_any:{[spec;dd;offset]
 funcs:r_d each first each spec;
 offsets:offset + (+\) {$[1=count[x];r_o[x];last x]} each spec;
 nchars:{$[1=count[x];::;last x]} each spec;
 funcs .' (count[spec]#enlist[enlist[dd]]),'{x where not null x} each offsets,'nchars}

r_sidedef:{[dd;offset]
 (r_short[dd;offset];
 r_short[dd;offset+2];
 r_chars[dd;offset+4;8];
 r_chars[dd;offset+12;8];
 r_chars[dd;offset+20;8];
 r_ushort[dd;offset+28])}

r_sidedefs:{[w;start;size]
 x:r_sidedef[w;] each start + s_sidedef * til size div s_sidedef;
 flip `xoffset`yoffset`upper_texture`lower_texture`middle_texture`sector!flip x}

r_vertex:{[dd;offset]
 r_short[dd;] each offset + 2 * til 2}

r_vertices:{[w;start;size]
 x:r_vertex[w;] each start + s_vertex * til size div s_vertex;
 flip `x`y!flip x}

r_seg:{[dd;offset]
 (r_ushort[dd;offset];
 r_ushort[dd;offset+2];
 r_short[dd;offset+4];
 r_ushort[dd;offset+6];
 r_short[dd;offset+8];
 r_short[dd;offset+10])}

r_segs:{[w;start;size]
 x:r_seg[w;] each start + s_seg * til size div s_seg;
 flip `v1`v2`angle`linedef`direction`offset!flip x}

r_level:{[w;lumps;name]
 idx:first exec i from lumps where lumpname like (name,"*");
 linedefs:r_linedefs[w;lumps[idx+2]`lumploc;lumps[idx+2]`lumpsize];
 sidedefs:r_sidedefs[w;lumps[idx+3]`lumploc;lumps[idx+3]`lumpsize];
 vertices:r_vertices[w;lumps[idx+4]`lumploc;lumps[idx+4]`lumpsize];
 segs:r_segs[w;lumps[idx+5]`lumploc;lumps[idx+5]`lumpsize];
 `linedefs`sidedefs`vertices`segs!(linedefs;sidedefs;vertices;segs)}