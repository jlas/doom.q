setd:{[d] ((set) .) each (enlist each key[t]),'(enlist each value[t])}

/ Size of binary byte structs
s_lump:16
s_thing:10
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
 r:flip cols_!flip ufunc[w;] each start + usize * til size div usize;
 / Make an id primary key
 `id xkey update id:i from r}

r_thing:r_any[`s`s`us`us`us;]
r_things:r_many[r_thing;s_thing;`x`y`angle`type_`flags]

r_linedef:r_any[7#`us;]
r_linedefs:r_many[r_linedef;s_linedef;`v1`v2`flags`type_`sector_tag`rsidedef`lsidedef;]

r_sidedef:r_any[(`s;`s;(`c;8);(`c;8);(`c;8);`us);]
r_sidedefs:r_many[r_sidedef;s_sidedef;`xoffset`yoffset`upper_texture`lower_texture`middle_texture`sector;]

r_vertex:r_any[2#`s;]
r_vertices:r_many[r_vertex;s_vertex;`x`y;]

r_seg:r_any[`us`us`s`us`s`s;]
r_segs:r_many[r_seg;s_seg;`v1`v2`angle`linedef`direction`offset;]

r_ssector:r_any[2#`s;]
r_ssectors:r_many[r_ssector;s_ssector;`numlines`firstline;]

r_node:r_any[14#`s;]
r_nodes:r_many[r_node;s_node;`x`y`dx`dy`bb1top`bb1bottom`bb1left`bb1right`bb2top`bb2bottom`bb2left`bb2right`lchild`rchild;]

r_sector:r_any[(`s;`s;(`c;8);(`c;8);`s;`us;`us)]
r_sectors:r_many[r_sector;s_sector;`floorheight`ceilheight`floortexture`ceiltexture`lightlevel`special`tag;]

r_level:{[w;lumps;name]
 idx:first exec i from lumps where lumpname like (name,"*");
 cols_:`things`linedefs`sidedefs`vertices`segs`ssectors`nodes`sectors;
 / Lookup the r_<lumpname> function and apply it with starting offset and size
 / Assumes lumps are laid out according to cols_
 call_lump_func:{[w;lumps;lumpname;idx] (`.[`$"r_",string lumpname])[w;lumps[idx]`lumploc;lumps[idx]`lumpsize]};
 cols_!call_lump_func[w;lumps;] .' cols_,'1 + idx + til count cols_}

render_sector:{0N!"called sector";}

render_bsp_node:{[nodes;bspnum]
 0N!"called with ",string bspnum;
 $[bspnum<0;render_sector[bspnum];.z.s[nodes;nodes[bspnum]`lchild]]}

t:r_level[w;lumps;"E1M1"];
setd[t];

ssectors:update `segs$`long$firstline from ssectors;
linedefs:update `vertices$v1, `vertices$v2 from linedefs;
segs:update `vertices$v1, `vertices$v2, `linedefs$linedef from segs;
sidedefs:update `sectors$sector from sidedefs;
ssectors:update `segs$`long$firstline from ssectors;

/ Replace the NF_SUBSECTOR macro (0x8000) with 0Nj to allow casting the column
linedefs:update
 lsidedef:`sidedefs$lsidedef:?[lsidedef<count[sidedefs];lsidedef;0Nj],
 rsidedef:`sidedefs$rsidedef:?[rsidedef<count[sidedefs];rsidedef;0Nj]
 from linedefs;

ML_TWOSIDED:0b vs 4i;

linedefs:update two_sided:{any ML_TWOSIDED & (0b vs x)} each flags from linedefs;

/ Add sidedef to segs
segs:update sidedef:`sidedefs$?[direction=0;linedef.rsidedef;linedef.lsidedef] from segs
segs:update bsidedef:`sidedefs$?[direction=1;linedef.rsidedef;linedef.lsidedef] from segs
segs:update bsidedef:0Nj from segs where not linedef.two_sided
