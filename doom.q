/ Size of binary byte structs
s_lump:16
s_linedef:14
s_sidedef:30
s_vertex:4
s_seg:12
s_ssector:4
s_node:28
s_sector:26

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

w:read1`:./doom1.wad

ident:"c"$w[til 4];
dirsize:r_int[w;4];
dirloc:r_int[w;8];
dirdata:w dirloc + til dirsize * s_lump

r_dir:{[dd;offset]
 (r_int[dd;offset]; r_int[dd;offset+4]; r_chars[dd;offset+8;8])}[dirdata;]

lumps:r_dir each s_lump * til dirsize;
lumps:`lumploc xasc flip `lumploc`lumpsize`lumpname!flip lumps;

/
 * Apply a generic data conversion to a bytes list according to a "spec" e.g.
 * the spec (`s;`s;(`c;8)) converts two shorts and an 8 byte character array.
 * @param {list} spec - a list of datatypes (keys in the r_d dict), optionally can
 *  include a nested list with data type and data size (e.g. in case of chars)
 * @param {bytes} dd - the bytes to convert
 * @param {int} offset - offset into dd
\
r_any:{[spec;dd;offset]
 funcs:r_d each first each spec;
 offsets:-1 _ offset + (+\) 0,{$[1=count[x];r_o[x];last x]} each spec;
 nchars:{$[1=count[x];::;last x]} each spec;
 funcs .' (count[spec]#enlist[enlist[dd]]),'{x where not null x} each offsets,'nchars}

r_many:{[ufunc;usize;cols_;w;start;size]
 flip cols_!flip ufunc[w;] each start + usize * til size div usize}

r_linedef:r_any[7#`us;]
r_linedefs:r_many[r_linedef;s_linedef;`v1`v2`flags`type`sector_tag`rsidedef`lsidedef;]

r_sidedef:r_any[(`s;`s;(`c;8);(`c;8);(`c;8);`us);]
r_sidedefs:r_many[r_sidedef;s_sidedef;`xoffset`yoffset`upper_texture`lower_texture`middle_texture`sector;]

r_vertex:r_any[2#`s]
r_vertices:r_many[r_vertex;s_vertex;`x`y;]

r_seg:r_any[`us`us`s`us`s`s;]
r_segs:r_many[r_seg;s_seg;`v1`v2`angle`linedef`direction`offset;]

r_ssector:r_any[2#`s]
r_ssectors:r_many[r_ssector;s_ssector;`numlines`firstline;]

r_node:r_any[14#`s]
r_nodes:r_many[r_node;s_node;`x`y`dx`dy`bb1top`bb1bottom`bb1left`bb1right`bb2top`bb2bottom`bb2left`bb2right`lchild`rchild;]

r_sector:r_any[(`s;`s;(`c;8);(`c;8);`s;`us;`us)]
r_sectors:r_many[r_sector;s_sector;`floorheight`ceilheight`floortexture`ceiltexture`lightlevel`special`tag;]

r_level:{[w;lumps;name]
 idx:first exec i from lumps where lumpname like (name,"*");
 cols_:`linedefs`sidedefs`vertices`segs`ssectors`nodes`sectors;
 / Lookup the r_<lumpname> function and apply it with starting offset and size
 / Assumes lumps are laid out according to cols_
 cols_!{[w;lumps;lumpname;idx] (`.[`$"r_",string lumpname])[w;lumps[idx]`lumploc;lumps[idx]`lumpsize]}[w;lumps;] .' cols_,'2 + idx + til count cols_}
