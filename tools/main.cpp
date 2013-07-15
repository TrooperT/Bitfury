// Copyright 2012 www.bitfury.org

// -inf=sha3r.xdl -outf=sha3m.xdl -macrobox=X98Y12:X127Y19 -routebox=X57Y12:X75Y19

#include <iostream>
#include "XDLParser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

using namespace std;
using namespace XDL;

string config_file;
string infile, outfile;


string chop_configname(const string& s, string::size_type pos)
{
    string result;
    while (pos < s.size() && s[pos] != ' ' && s[pos] != '\n' && s[pos] != '\r' && s[pos] != '\t') { result += s[pos]; pos ++; }
    return result;
}

struct PosRect { int minx, miny, maxx, maxy; };
typedef vector<PosRect> PosRects;

PosRects macro_boxes, routing_boxes;

PosRects parse_posrects(const char *p)
{
    PosRect cur;
    PosRects result;

    // XnnYnn:XnnYnn,XnnYnn:XnnYnn,....
    for (;;) {
        while (*p && (*p == ' ' || *p == '\r' || *p == '\n' || *p == '\t')) p++;
        if (!*p) return result;
        if (*p == 'X' || *p == 'x') p ++; else return result;
        cur.minx = atoi(p);
        while (*p >= '0' && *p <= '9') p++;
        if (*p == 'Y') p++; else return result;
        cur.miny = atoi(p);
        while (*p >= '0' && *p <= '9') p++;
        if (*p == ':') p++; else return result;
        if (*p == 'X' || *p == 'x') p ++; else return result;
        cur.maxx = atoi(p);
        while (*p >= '0' && *p <= '9') p++;
        if (*p == 'Y') p++; else return result;
        cur.maxy = atoi(p);
        result.push_back(cur);
        while (*p >= '0' && *p <= '9') p++;
        if (*p == ',') p++; else return result;
    }
    return result;
}

static void fix_configuration(const string& comp_name, Design::nets_type, string& cfg);
std::string out_net_format(std::string net_name) { return net_name; }
std::string in_net_format(std::string net_name) { return net_name; }
std::string net_to_port_name(std::string net_name)
{
    std::string rv = net_name;
    for (unsigned i = 0; i < rv.size(); i++) if (rv[i] == '[') rv[i] = '<'; else if (rv[i] == ']') rv[i] = '>';
    return rv;
}

int idx = 10000;
std::string new_idx(void)
{
    idx++;
    char s[32];
    sprintf(s,"%d",idx);
    return s;
}

int hardmacro_gen()
{
    Design d;
    bool reloc = true;
    bool mergepwr = true;

    if (config_file.find("-fixedmacro") < config_file.size()) reloc = false;
    if (config_file.find("-nopwr") < config_file.size()) {
        printf("Warning! This macro couldn\'t be used by Xilinx Tools as power nets are not merged and some tieoffs are not removed!\n");
        mergepwr = false;
    }

    if (!d.load(infile.c_str())) {
        printf("Failed to load design %s\n", infile.c_str());
        return 1;
    }

    d.modules.clear(); // Remove other hardmacros (if any)

    string module_name = "default_module";
    string::size_type npos = config_file.size();
    npos = config_file.find("-module=");
    if (npos < config_file.size()) module_name = chop_configname(config_file, npos+8);

    npos = config_file.find("-outnet=");
    vector<string> outnets;
    while (npos < config_file.size()) {
        npos += 8;
        string net = chop_configname(config_file, npos);
        npos = config_file.find("-outnet=", npos);
        outnets.push_back(net);
    }
    npos = 0;

    printf("Generating hardmacro module %s from design %s\n", module_name.c_str(), infile.c_str());

    Module& m = d.modules[module_name];
    m.cfg = "_SYSTEM_MACRO::FALSE";

    // Extract components into hardmacro!
    // 12..19 line is components that belongs to module that we want to chop-chop!
    int rx = 128, ry = 196;

    // Extract all VCC and GND pins
    vector<Pin> vcc_pins, gnd_pins;
    vector<string> kill_nets;
    vector<string>::iterator ki;

    Design::nets_type::iterator ni;
    Design::insts_type::iterator ii;
    Net::inpin_type::iterator nin;

    if (mergepwr) {
        // Extract pin information from VCC / GND nets
        printf("Extracting VCC/GND nets...\n");
        for (ni = d.nets.begin(); ni != d.nets.end(); ni ++) {
            if (ni->second.pwr == "vcc" || ni->first.substr(0,13) == "GLOBAL_LOGIC1") {
                for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) vcc_pins.push_back(*nin);
                ii = d.insts.find(ni->second.outpin.comp); if (ii->second.place.substr(0,6) == "TIEOFF" && ii != d.insts.end()) d.insts.erase(ii);
                kill_nets.push_back(ni->first);
            }
            if (ni->second.pwr == "gnd" || ni->first.substr(0,13) == "GLOBAL_LOGIC0") {
                for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) gnd_pins.push_back(*nin);
                ii = d.insts.find(ni->second.outpin.comp); if (ii->second.place.substr(0,6) == "TIEOFF" && ii != d.insts.end()) d.insts.erase(ii);
                kill_nets.push_back(ni->first);
            }
        }
    }


    PosRects::iterator pri;

    // Extract all instances
    for (pri = macro_boxes.begin(); pri != macro_boxes.end(); pri ++) {
        printf("Extracting instances from BOX X%dY%d:X%dY%d\n", pri->minx, pri->miny, pri->maxx, pri->maxy);

        for (ii = d.insts.begin(); ii != d.insts.end(); ii++) {
            if (ii->second.place.substr(0,5) != "SLICE") continue; // Only slices!
            int ypos = parse_slice_y(ii->second.place);
            if (ypos >= pri->miny && ypos <= pri->maxy) {
                int xpos = parse_slice_x(ii->second.place);
                if (xpos >= pri->minx && xpos <= pri->maxx) {
                    if (xpos < rx || (xpos == rx && ypos <= ry)) {
                        rx = xpos;
                        ry = ypos;
                        m.refcomp = ii->first;
                    }
                    ii->second.module_inst.clear();
                    ii->second.module.clear();
                    ii->second.module_int_inst.clear();
                    m.insts[ii->first] = ii->second;
                }
            }
        }
    }

    if (!mergepwr) for (pri = routing_boxes.begin(); pri != routing_boxes.end(); pri++) {
        for (ii = d.insts.begin(); ii != d.insts.end(); ii++) {
            if (ii->second.place.substr(0,6) != "TIEOFF") continue; // Only TIEOFFs!
            int ypos = parse_slice_y(ii->second.place_switch);
            if (ypos >= pri->miny && ypos <= pri->maxy) {
                int xpos = parse_slice_x(ii->second.place_switch);
                if (xpos >= pri->minx && xpos <= pri->maxx) {
                    if (xpos < rx || (xpos == rx && ypos <= ry)) {
                        rx = xpos;
                        ry = ypos;
                        m.refcomp = ii->first;
                    }
                    ii->second.module_inst.clear();
                    ii->second.module.clear();
                    ii->second.module_int_inst.clear();
                    m.insts[ii->first] = ii->second;
                }
            }
        }
    }

    for (ii = d.insts.begin(); ii != d.insts.end(); ii++) {
        if (ii->second.place.substr(0,5) == "SLICE") continue;
        if (ii->second.place.substr(0,6) == "TIEOFF") continue;
        if (config_file.find(ii->second.place) >= config_file.size()) {
            printf("Not extracting special comp %s inst %s\n", ii->second.place.c_str(), ii->first.c_str());
            continue;
        }
        printf("Extracting special comp %s inst %s\n", ii->second.place.c_str(), ii->first.c_str());
        ii->second.module_inst.clear();
        ii->second.module.clear();
        ii->second.module_int_inst.clear();
        m.insts[ii->first] = ii->second;
    }

    if (!mergepwr) {
        // Extract pin information from VCC / GND nets
        printf("Extracting VCC/GND with dropped tieoffs...\n");
        for (ni = d.nets.begin(); ni != d.nets.end(); ni ++) {
            if (ni->second.pwr == "vcc" || ni->first.substr(0,13) == "GLOBAL_LOGIC1") {
                if (m.insts.find(ni->second.outpin.comp) != m.insts.end()) continue; // TIEOFF PRESENT!
                for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) vcc_pins.push_back(*nin);
                ii = d.insts.find(ni->second.outpin.comp); if (ii->second.place.substr(0,6) == "TIEOFF" && ii != d.insts.end()) d.insts.erase(ii);
                kill_nets.push_back(ni->first);
            }
            if (ni->second.pwr == "gnd" || ni->first.substr(0,13) == "GLOBAL_LOGIC0") {
                if (m.insts.find(ni->second.outpin.comp) != m.insts.end()) continue; // TIEOFF PRESENT!
                for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) gnd_pins.push_back(*nin);
                ii = d.insts.find(ni->second.outpin.comp); if (ii->second.place.substr(0,6) == "TIEOFF" && ii != d.insts.end()) d.insts.erase(ii);
                kill_nets.push_back(ni->first);
            }
        } // Nets with absent tieoffs will be merged into GLOBAL_LOGIC1 / GLOBAL_LOGIC0 nets
    }

    // Kill routing and some specific nets
    if (config_file.find("-killnet=") < config_file.size() || config_file.find("-killroutes=") < config_file.size()) {
        printf("Killing routing and/or specified nets completely from macro\n");
        string::size_type np = config_file.find("-killnet=");
        while (np < config_file.size()) {
            np += 9;
            kill_nets.push_back(chop_configname(config_file,np));
            np = config_file.find("-killnet=",np);
        }
        np = config_file.find("-killroutes=");
        while (np < config_file.size()) {
            np += 12;
            string tk = chop_configname(config_file, np);
            ni = d.nets.find(tk);
            if (ni != d.nets.end()) ni->second.routing.clear(); // Remove pips!
            np = config_file.find("-killroutes=",np);
        }
    }


    // Kill all VCC and GND nets
    printf("Killing queued VCC/GND nets\n");
    for (ki = kill_nets.begin(); ki != kill_nets.end(); ki++)
        { ni = d.nets.find(*ki); if (ni != d.nets.end()) d.nets.erase(ni); }

    bool gpwrpin = false;

    // Generate ports for `0' and `1' input
    for (nin = vcc_pins.begin(); nin != vcc_pins.end(); nin++) {
        if (m.insts.find(nin->comp) != m.insts.end()) {
            string net_name("GLOBAL_LOGIC1");

            gpwrpin = true;
            Net& n = m.nets[net_name+"_999999"];
            n.inpin.push_back(*nin);
            m.ports[net_name+"_in"].inst = nin->comp;
            m.ports[net_name+"_in"].pin = nin->pin;
        }
    }

    for (nin = gnd_pins.begin(); nin != gnd_pins.end(); nin++) {
        if (m.insts.find(nin->comp) != m.insts.end()) {
            string net_name("GLOBAL_LOGIC0");

            gpwrpin = true;
            Net& n = m.nets[net_name+"_999999"];
            n.inpin.push_back(*nin);
            m.ports[net_name+"_in"].inst = nin->comp;
            m.ports[net_name+"_in"].pin = nin->pin;
        }
    }

    if (gpwrpin) printf("Generated GLOBAL_LOGIC0_in and GLOBAL_LOGIC1_in...\n");

    int cnt_preserve = 0, cnt_drop = 0, cnt_in = 0, cnt_out = 0;

    map<string,map<string, bool> > nettab;
    for (ni = d.nets.begin(); ni != d.nets.end(); ni ++) {
        if (ni->second.outpin.comp.size() < 1) continue;
        if (m.insts.find(ni->second.outpin.comp) == m.insts.end()) continue; // Do not bother...
        for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) {
            if (m.insts.find(nin->comp) == m.insts.end()) continue; // Ignore outside
            nettab[ni->second.outpin.comp][nin->comp] = true;
        }
    }

    printf("Processing netlist...\n");

    // Netlist processing is more complex!
    for (ni = d.nets.begin(); ni != d.nets.end(); ni ++) {
        if (mergepwr && ni->second.outpin.comp.size() < 1 && ni->second.pwr.size() > 0) ni->second.pwr.clear();
        if (m.insts.find(ni->second.outpin.comp) != m.insts.end()) {
            // Signal originates from our macro, if it does not cross any boundary, then it is internal
            for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++)
                if (m.insts.find(nin->comp) == m.insts.end()) break;

            if (nin == ni->second.inpin.end() && ni->second.inpin.size() > 0) {
                Net::routing_type::iterator ri;
                bool preserve = true;

                for (ri = ni->second.routing.begin(); ri != ni->second.routing.end(); ri ++) {
                    if (reloc && ri->tile.substr(0,13) == "INT_BRAM_BRK_") preserve = false;
                    if (reloc && ri->tile.substr(0,4) == "IOI_") preserve = false;
                    if (ri->tile.substr(0,3) == "CLE" || ri->tile.substr(0,3) == "INT" || ri->tile.substr(0,7) == "IOI_INT") {
                        int x = parse_slice_x(ri->tile), y = parse_slice_y(ri->tile);
                        bool boxfound = false;
                        for (pri = routing_boxes.begin(); pri != routing_boxes.end(); pri++)
                            if (x >= pri->minx && x <= pri->maxx && y >= pri->miny && y <= pri->maxy ) { boxfound = true; break; }
                        if (!boxfound) preserve = false;
                    }
                }

                Net &dnet = m.nets[ni->first];
                dnet.outpin = ni->second.outpin;
                dnet.inpin = ni->second.inpin;
                if (!mergepwr && ni->second.pwr.size() > 0) dnet.pwr = ni->second.pwr;

                for (vector<string>::iterator oi = outnets.begin(); oi != outnets.end(); oi ++) {
                    if (*oi == ni->first.substr(0, oi->size())) {
                        string newport = net_to_port_name(ni->first);
                        m.ports[newport].inst = ni->second.outpin.comp;
                        m.ports[newport].pin = ni->second.outpin.pin;
                        preserve = false;
                        break;
                    }
                }

                if (preserve) { cnt_preserve ++; dnet.routing = ni->second.routing; } else { cnt_drop ++; }
            } else {
                if (!mergepwr) {
                    for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++)
                        if (m.insts.find(nin->comp) != m.insts.end()) break;
                    // Not found _any_ consumer of signal! Candidate for complete comp. removal!
                    if (nin == ni->second.inpin.end() && nettab[ni->second.outpin.comp].size() == 0 && (ni->second.pwr.size() > 0 || ni->first.find("GLOBAL_LOGIC") < ni->first.size())) {
                        m.insts.erase(m.insts.find(ni->second.outpin.comp));
                        continue; // Ignore this net completely and remove component
                    }
                }

                string newnet = out_net_format(ni->first); // Rename net
                string newport = net_to_port_name(newnet); // Make name for port
                m.ports[newport].inst = ni->second.outpin.comp;
                m.ports[newport].pin = ni->second.outpin.pin;

                Net &dnet = m.nets[newnet];
                dnet.outpin = ni->second.outpin;
                if (!mergepwr && ni->second.pwr.size() > 0) dnet.pwr = ni->second.pwr;
                cnt_out++;

                // Add to this net only those who belong to our module!
                for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++)
                    if (m.insts.find(nin->comp) != m.insts.end())
                        dnet.inpin.push_back(*nin);
            }
        } else {
            for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++)
                if (m.insts.find(nin->comp) != m.insts.end()) break;
            if (nin == ni->second.inpin.end()) continue;

            // Port and net generation!
            string netname = in_net_format(ni->first);
            string portname = net_to_port_name(netname);
            Port &dport = m.ports[portname];
            Net &dnet = m.nets[netname];
            if (!mergepwr && ni->second.pwr.size() > 0) dnet.pwr = ni->second.pwr;
            cnt_in ++;
            for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) if (m.insts.find(nin->comp) != m.insts.end()) {
                dnet.inpin.push_back(*nin);
                dport.inst = nin->comp;
                dport.pin = nin->pin;
            }
        }
    }

    printf("Preserved: %d nets, dropped routing %d nets, inputs %d nets, output %d nets\n", cnt_preserve, cnt_drop, cnt_in, cnt_out);
    printf("Verifying that all drivers for all nets exists and all inpins have components\n");

    map<string, bool> usedcomps;
    for (ni = m.nets.begin(); ni != m.nets.end(); ni ++) {
        if (ni->second.outpin.comp.size() > 0) {
            usedcomps[ni->second.outpin.comp] = true;
            if (m.insts.find(ni->second.outpin.comp) == m.insts.end()) {
                printf("Net %s exists but driver comp %s does not!\n", ni->first.c_str(), ni->second.outpin.comp.c_str());
            }
        }
        for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin ++) {
            usedcomps[nin->comp] = true;
            if (m.insts.find(nin->comp) == m.insts.end()) {
                printf("Net %s has input pin of %s but comp does not exists!\n", ni->first.c_str(), nin->comp.c_str());
            }
        }
    }

    printf("Verifying that all components are used on nets!\n");
    for (ii = m.insts.begin(); ii != m.insts.end(); ii++) {
        if (usedcomps.find(ii->first) == usedcomps.end()) {
            printf("Component %s is not used on any net!\n", ii->first.c_str());
        }
    }

    // Remove elements from a design
    d.nets.clear();
    d.insts.clear();
    d.cfg.clear();
//    d.version.clear();
    d.name = "__XILINX_NMC_MACRO";

    if (outfile.size() > 0) {
        if (!d.save(outfile.c_str())) {
            printf("Unable to save %s\n", outfile.c_str());
            return 1;
        }
    }
    return 0;
}

const char *lut5names[4] = { "A5LUT", "B5LUT", "C5LUT", "D5LUT" };
const char *lut6names[4] = { "A6LUT", "B6LUT", "C6LUT", "D6LUT" };

static string::iterator lutfind_name(string& str, const char *ln, const char *nam)
{
    string::iterator s = str.begin(), e = str.end();
    if (s == e) return e;
    int idx = 0;
    for (idx = 0; s < e && ln[idx]; s++) if (*s == ln[idx]) idx++; else idx = 0;
    if (ln[idx]) return e;
    for (idx = 0; s < e && nam[idx]; s ++) {
        if (*s == ' ' || *s == '\n' || *s == '\r' || *s == '\t') break;
        if (*s == nam[idx]) idx++; else idx = 0;
    }
    if (nam[idx]) return e;
    return s;
}

static string::iterator lutfind_end(string::iterator s, string::iterator e)
{
    while (s < e && *s != '\n' && *s != ' ' && *s != '\r' && *s != '\t') s++;
    return s;
}

//
// LUT EQUATIONS:
// + means OR
// ~ means NOT
// @ means XOR
// * means AND
//
static string fix_lut(const string& lut5, const string& lut6)
{
    // I have stopped using this kind of harmonization, because this will introduce
    // false paths measured by PAR
    if (lut6.substr(0,9) == "(A6+~A6)*") {
        string eq1 = lut6.substr(9);
        string result = "((A6*"+eq1+")+(~A6*"+lut5+"))";
//        printf("HARMONIZE O5=%s O6=%s => %s\n", lut5.c_str(), lut6.c_str(), result.c_str());
        return result;
    }
    return lut6;
}

static void fix_configuration(const string& comp_name, Design::nets_type, string& cfg)
{
    int i;
    for (i = 0; i < 4; i++) {
        string::iterator l5 = lutfind_name(cfg, lut5names[i], ":#LUT:O5=");
        string::iterator l6 = lutfind_name(cfg, lut6names[i], ":#LUT:O6=");
        if (l5 == cfg.end() || l6 == cfg.end()) continue;
        string::iterator l5e = lutfind_end(l5, cfg.end());
        string::iterator l6e = lutfind_end(l6, cfg.end());
        string newc = fix_lut(string(l5,l5e), string(l6, l6e));
        cfg.replace(l6, l6e, newc);
    }
}

const char *acp_prefix_names[] =
{
    "A5LUT:", "A6LUT:", "B5LUT:", "B6LUT:", "C5LUT:", "C6LUT:", "D5LUT:", "D6LUT:",
    "AFF:", "BFF:", "CFF:", "DFF:", "A5FF:", "B5FF:", "C5FF:", "D5FF:",
    "_INST_PROP::XDL_SHAPE_MEMBER:", "_INST_PROP::XDL_SHAPE_DESC:", "CARRY4:", (char*)0
};

static void add_config_prefix(string& s, const string& pref)
{
    int i;
    for (i = 0; acp_prefix_names[i]; i++) {
        const char *needle = acp_prefix_names[i];
        string::size_type npos = 0;
        while (npos < s.size()) {
            npos = s.find(needle, npos);
            if (npos >= s.size()) break;
            if (npos > 0 && s[npos-1] != ' ' && s[npos-1] != '\t' && s[npos-1] != '\n' && s[npos-1] != '\r') {
                npos += strlen(needle);
                continue;
            }
            npos += strlen(needle);
            if (npos >= s.size()) continue;
            if (s[npos] == ' ' || s[npos] == '\n' || s[npos] == '\t' || s[npos] == '\r' || s[npos] == ':') continue;
            s = s.substr(0,npos) + pref + s.substr(npos, s.size());
        }
    }
}

void placer_relocate(string &s, int dy)
{
    string::size_type npos = s.find("_X");
    if (npos >= s.size()) return;
    while (npos < s.size() && s[npos] != 'Y') npos++; // Find Y element
    if (npos >= s.size()) return;
    npos++;
    int newy = atoi(s.c_str()+npos) + dy;
    char newys[32]; sprintf(newys,"%d", newy);
    s = s.substr(0, npos) + string(newys);
}

int run_placer(void)
{
    Design out; // Output design stage
    map<string, Design> dcache; // Design cache

    string::size_type npos = 0;
    npos = config_file.find("-ldesign=");
    if (npos < config_file.size()) {
        string dname = chop_configname(config_file, npos+9);
        if (!out.load(dname)) {
            printf("Failed to load design %s\n", dname.c_str());
            return 1;
        }
    }
    npos = config_file.find("-design=");
    if (npos < config_file.size()) out.name = chop_configname(config_file, npos+8);
    npos = 0;

    Design::nets_type::iterator ni;

    for (;;) {
        npos = config_file.find("-place=",npos);
        if (npos >= config_file.size()) break;
        npos += 7;
        string placer = chop_configname(config_file, npos);
        string::size_type cpos = placer.find(',');
        if (cpos >= placer.size()) continue;
        string mfn = placer.substr(0, cpos); placer = placer.substr(cpos+1, placer.size());
        if ((cpos = placer.find(',')) >= placer.size()) continue;
        string pref = placer.substr(0, cpos); placer = placer.substr(cpos+1, placer.size());
        if ((cpos = placer.find(',')) >= placer.size()) continue;
        string reloc = placer.substr(0, cpos); placer = placer.substr(cpos+1, placer.size());
        map<string,string> portnet;
        while (placer.size() > 0) {
            string subs;
            cpos = placer.find(',');
            if (cpos < placer.size()) { subs = placer.substr(0,cpos); placer = placer.substr(cpos+1, placer.size()); } else { subs = placer; placer.clear(); }
            cpos = subs.find(':');
            if (cpos >= subs.size()) continue;
            portnet[subs.substr(0,cpos)] = subs.substr(cpos+1,subs.size());
        }

        if (mfn.find(".xdl") >= mfn.size() || mfn.find(".XDL") >= mfn.size()) mfn += ".xdl";

        Design dm;

        printf("Loading %s prefix will be %s\n", mfn.c_str(), pref.c_str());
        if (dcache.find(mfn) != dcache.end()) {
            dm = dcache[mfn];
        } else {
            if (!dm.load(mfn.c_str())) {
                printf("Failed to load %s\n", mfn.c_str());
                return 1;
            }
            dcache[mfn] = dm;
        }

        if (dm.modules.begin() == dm.modules.end()) {
            printf("No modules found in %s\n", mfn.c_str());
            return 1;
        }
        Module& m = dm.modules.begin()->second; // Get module to manipulate!

        if (out.device.size() == 0) {
            out.version = dm.version;
            out.device = dm.device;
        } else {
            if (out.device != dm.device || out.version != dm.version) {
                printf("Mixing of versions not allowed (module %s %s %s) target %s %s\n", mfn.c_str(), dm.device.c_str(), dm.version.c_str(), out.device.c_str(), out.version.c_str());
                return 1;
            }
        }

        Design::insts_type::iterator ii;
        Net::inpin_type::iterator nin;
        Net::routing_type::iterator ri;

        ii = m.insts.find(m.refcomp); if (ii == m.insts.end()) { printf("Reference comp not found\n"); return 1; }
        int dy = 0;

        if (reloc != "n") {
            if (parse_slice_x(ii->second.place.c_str()) != parse_slice_x(reloc.c_str())) {
                printf("Moving along X axis requires internal knowledge of chip and not allowed (%s -> %s)\n", ii->second.place.c_str(), reloc.c_str());
                return 1;
            }
            dy = parse_slice_y(reloc.c_str()) - parse_slice_y(ii->second.place.c_str());
        }

        // Perform relocation of all components... and extract them to design with adding prefix!
        printf("Moving along Y axis for %d and extracting components... \n", dy);
        for (ii = m.insts.begin(); ii != m.insts.end(); ii++) {
            if (dy) {
                placer_relocate(ii->second.place, dy);
                placer_relocate(ii->second.place_switch, dy);
            }
            add_config_prefix(ii->second.cfg, pref);
            out.insts[pref+ii->first] = ii->second;
        }

        // Build table for net renamer comp -> pin -> net name
        map<string, map<string, string > > net_renamer;
        Module::ports_type::iterator pi;
        for (pi = m.ports.begin(); pi != m.ports.end(); pi++) {
            for (map<string,string>::iterator pni = portnet.begin(); pni != portnet.end(); pni++) {
                if (pni->first == pi->first.substr(0, pni->first.size())) { // Prefixes MATCH
                    string net_name = pni->second + pi->first.substr(pni->first.size(), pi->first.size());
                    unsigned i;
                    for (i = 0; i < net_name.size();i++) if (net_name[i] == '<') net_name[i] = '['; else if (net_name[i] == '>') net_name[i] = ']';
                    net_renamer[pi->second.inst][pi->second.pin] = net_name;
                }
            }
        }

        // Perform relocation of all pips...
        printf("Moving along Y axis for %d and extracting nets... \n", dy);
        for (ni = m.nets.begin(); ni != m.nets.end(); ni++) {
            if (dy) for (ri = ni->second.routing.begin(); ri != ni->second.routing.end(); ri ++) placer_relocate(ri->tile, dy);
            string net_name = pref + ni->first;

            map<string, map<string,string> >::iterator nren_i;
            map<string,string>::iterator nren_i1;

            for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++) {
                nren_i = net_renamer.find(nin->comp);
                if (nren_i != net_renamer.end()) {
                    nren_i1 = nren_i->second.find(nin->pin);
                    if (nren_i1 != nren_i->second.end()) {
                        net_name = nren_i1->second;
                        if (net_name.size() > 0 && net_name[0] == '~') {
                            net_name = net_name.substr(1,net_name.size()); // Remove tilda from the net name!
                            for (Net::inpin_type::iterator nin1 = ni->second.inpin.begin(); nin1 != ni->second.inpin.end(); nin1++) {
                                Instance *inst = 0;
                                if (out.insts.find(pref + nin1->comp) != out.insts.end()) {
                                    inst = &out.insts[pref+nin1->comp];
                                } else if (out.insts.find(nin1->comp) != out.insts.end()) { // Already patched
                                    inst = &out.insts[nin1->comp];
                                }
                                if (!inst) { printf("Warning, unable to locate component %s\n", nin1->comp.c_str()); continue; }
                                unsigned pos = inst->cfg.find("CLKINV::CLK");
                                if (pos < inst->cfg.size()) { // Great! Add _B - this would make INVERTED clock
                                    string::iterator p = inst->cfg.begin()+pos+11;
                                    inst->cfg.replace(p,p,"_B");
                                }
                            }
                        }
                    }
                }
                nin->comp = pref + nin->comp; // Add prefix
            }

            if (ni->second.outpin.comp.size() > 0) {
                nren_i = net_renamer.find(ni->second.outpin.comp);
                if (nren_i != net_renamer.end()) {
                    nren_i1 = nren_i->second.find(ni->second.outpin.pin);
                    if (nren_i1 != nren_i->second.end()) net_name = nren_i1->second;
                }
                ni->second.outpin.comp = pref + ni->second.outpin.comp;
            }

            // Simply add new net
            if (out.nets.find(net_name) == out.nets.end()) {
                out.nets[net_name] = ni->second;
                continue;
            }

            // Perform merger of two nets!
            Net &tn = out.nets[net_name];
            if (ni->second.outpin.comp.size() > 0) {
                if (tn.outpin.comp.size() > 0) {
                    printf("Net %s has driver from comp %s but module wants to drive it from %s\n", net_name.c_str(), tn.outpin.comp.c_str(), ni->second.outpin.comp.c_str());
                    return 1;
                }
                tn.outpin.comp = ni->second.outpin.comp;
                tn.outpin.pin = ni->second.outpin.pin;
            }

            for (nin = ni->second.inpin.begin(); nin != ni->second.inpin.end(); nin++)
                tn.inpin.push_back(*nin); // Add some input pins there

            tn.routing.clear(); // Clear routing (if any) for merged nets!
        }

        printf("Module %s prefix %s relocate at %s\n", mfn.c_str(), pref.c_str(), reloc.c_str());
    }

    // Collect all power nets! rename them to GLOBAL_LOGIC0 / GLOBAL_LOGIC1 (!)

    vector<string> net_removal;
    Design::nets_type net_copy;
    unsigned gl0_cnt = 0, gl1_cnt = 0;

    for (ni = out.nets.begin(); ni != out.nets.end(); ni++) {
        if (ni->first.find("GLOBAL_LOGIC0") < ni->first.size()) {
            char s[64];
            sprintf(s, "GLOBAL_LOGIC0_%u", gl0_cnt);
            ni->second.pwr = "gnd";
            net_copy[s] = ni->second;
            net_removal.push_back(ni->first);
            gl0_cnt++;
        }
        if (ni->first.find("GLOBAL_LOGIC1") < ni->first.size()) {
            char s[64];
            sprintf(s, "GLOBAL_LOGIC1_%u", gl1_cnt);
            ni->second.pwr = "vcc";
            net_copy[s] = ni->second;
            net_removal.push_back(ni->first);
            gl1_cnt++;
        }
    }

    // Process drop-routing statements, to chop non-existing routing places
    for (vector<string>::iterator nrem = net_removal.begin(); nrem != net_removal.end(); nrem ++)
        if ((ni = out.nets.find(*nrem)) != out.nets.end()) out.nets.erase(ni);

    for (ni = net_copy.begin(); ni != net_copy.end(); ni++) out.nets[ni->first] = ni->second;

    npos = config_file.find("-killroute=");
    while (npos < config_file.size()) {
        npos += 11;
        string nname = chop_configname(config_file, npos);
        if (out.nets.find(nname) != out.nets.end()) {
            printf("Killing routing of %s\n", nname.c_str());
            out.nets[nname].routing.clear();
        }
        npos = config_file.find("-killroute=", npos);
    }

    npos = config_file.find("-killnet=");
    while (npos < config_file.size()) {
        npos += 9;
        string nname = chop_configname(config_file, npos);
        if (out.nets.find(nname) != out.nets.end()) {
            printf("Killing net %s\n", nname.c_str());
            out.nets.erase(out.nets.find(nname));
        }
        npos = config_file.find("-killnet=", npos);
    }

    out.cfg = "\r\n\t_DESIGN_PROP:P3_PLACE_OPTIONS:EFFORT_LEVEL:high\r\n\t_DESIGN_PROP::P3_PLACED:\r\n\t_DESIGN_PROP::P3_PLACE_OPTIONS:\r\n\t_DESIGN_PROP::PK_NGMTIMESTAMP:1319873087\r\n";
    printf("Saving to %s\n", outfile.c_str());
    if (outfile.size() > 0) {
        if (!out.save(outfile.c_str())) {
            printf("Failed to save %s\n", outfile.c_str());
            return 1;
        }
    }
    return 0;
}

int pinswapfix(void)
{
    string::size_type npos = config_file.find("-pinswapfix=");
    string pswapf;
    if (npos < config_file.size()) {
        npos += 12;
        pswapf = chop_configname(config_file, npos);
    } else { printf("Pinswap file not specified\n"); return 1; }

    Design d_orig, d;
    printf("Loading original design: %s\n", pswapf.c_str());
    if (!d_orig.load(pswapf)) { printf("Unable to load original design %s\n", pswapf.c_str()); return 1; }
    printf("Loading routed design: %s\n", infile.c_str());
    if (!d.load(infile)) { printf("Unable to load routed design %s\n", infile.c_str()); return 1; }

    Design::nets_type::iterator ni;
    Design::insts_type::iterator ii;
    Net::inpin_type::iterator nin;
    Net::routing_type::iterator ri;

    map<Pin, string> inpins;
    map<Pin, string> outpins;
    map<string, bool> compfix; // Components to fix
    map<string, bool> netfix;  // Nets to fix

    // Find signals that failed after pinswap...
    for (ni = d.nets.begin(); ni != d.nets.end(); ni++) {
        if (ni->first.substr(0,12) == "GLOBAL_LOGIC") continue; // Ignore GLOBAL_LOGIC nets
        if (d_orig.nets.find(ni->first) == d_orig.nets.end()) {
                printf("Failed to locate same net (%s) on original!\n", ni->first.c_str());
                return 1;
        }
        Net& orig = d_orig.nets[ni->first]; Net &n = ni->second;
        if (orig.outpin.comp.size() > 0 && n.outpin.comp.size() < 1) {
            printf("On net %s output pin was dropped by router\n", ni->first.c_str());
            return 1;
        }

        if (n.outpin.comp.size() > 0) {
            outpins[n.outpin] = ni->first;
            if (orig.outpin.comp.size() < 1) {
                printf("On net %s output pin emerged!\n", ni->first.c_str());
                return 1;
            }
        }
        for (nin = n.inpin.begin(); nin != n.inpin.end(); nin++) {
            if (inpins.find(*nin) != inpins.end()) {
                printf("Found failed PIN %s %s on net %s (already on %s)\n", nin->comp.c_str(), nin->pin.c_str(), ni->first.c_str(), inpins[*nin].c_str());
                compfix[nin->comp] = true;
                netfix[ni->first] = true;
                netfix[inpins[*nin]] = true;
            } else {
                inpins[*nin] = ni->first;
            }
        }
    }

    // Remove all pin connections to components that we're going to fix
    for (map<string,bool>::iterator nfi = netfix.begin(); nfi != netfix.end(); nfi++) {
        Net &n = d.nets[nfi->first];
        bool cont = false;
        do {
            cont = false;
            for (nin = n.inpin.begin(); nin != n.inpin.end(); nin++) {
                if (compfix.find(nin->comp) != compfix.end()) {
                    n.inpin.erase(nin); // Remove connection to mentioned component
                    n.routing.clear();  // Remove routing
                    cont = true;
                    break;
                }
            }
        } while (cont);
    }

    // Copy original components
    for (map<string,bool>::iterator cfi = compfix.begin(); cfi != compfix.end(); cfi++) d.insts[cfi->first] = d_orig.insts[cfi->first];

    // Copy nets from original back
    for (ni = d_orig.nets.begin(); ni != d_orig.nets.end(); ni++) {
        Net &no = d_orig.nets[ni->first], &n = d.nets[ni->first];
        for (nin = no.inpin.begin(); nin != no.inpin.end(); nin ++) {
            if (compfix.find(nin->comp) != compfix.end()) {
                n.inpin.push_back(*nin);
            }
        }
    }

    // TODO - implement LUT validator and reverse to original if LUT validation fails!

    printf("Saving routed fixed design: %s\n", outfile.c_str());
    if (!d.save(outfile)) { printf("Unable to save output file %s\n", outfile.c_str()); return 1; }
    return 0;
}

unsigned fix_index_instance_nmlookup(string::iterator b, string::iterator e)
{
    string lnam = string(b,e); // Name of LUT
    string::size_type npos = lnam.find("REXP0/BG[");
    if (npos < lnam.size()) {
        if (lnam.find("ADDL6") >= lnam.size()) return 0;
        npos += 9;
        if (npos >= lnam.size()) return 0;
        unsigned idx = (unsigned)atoi(lnam.c_str() + npos);
        if (idx > 0 && idx < 8) return idx;
        return 0;
    }
    npos = lnam.find("MATCH/GMUC");
    if (npos >= lnam.size()) return 0; // Not found!
    npos += 12; if (npos >= lnam.size()) return 0;
    return 9 + (unsigned)atoi(lnam.c_str()+npos);
}

const char *lutanames[8] = { "A5LUT", "A6LUT", "B5LUT", "B6LUT", "C5LUT", "C6LUT", "D5LUT", "D6LUT" };
const char *lutffnames[8] = { "A5FF:", "AFF:", "B5FF:", "BFF:", "C5FF:", "CFF:", "D5FF:", "DFF:" };
const char *lutfinames[8] = { "A5FFSRINIT:", "AFFSRINIT:", "B5FFSRINIT:", "BFFSRINIT:", "C5FFSRINIT:", "CFFSRINIT:", "D5FFSRINIT:", "DFFSRINIT:" };

string replace_W_formula(const string& formula, unsigned bitflag, int i, const string& comp)
{
    // 30... +Ax) 34
    // 30... *~Ax) 35
    if (formula.size() == 35) { // Bit is 0
//        printf("replace_W_formula(0) i = %d formula = %s comp = %s\n", i, formula.c_str(), comp.c_str());
        if (!bitflag) return formula; // Do nothing
        string newformula(formula);
        newformula.replace(newformula.begin()+30,newformula.begin()+32, "+");
//        printf("New formula is %s\n", newformula.c_str());
        return newformula;
    }
    if (formula.size() == 34) { // Bit is 1
//        printf("replace_W_formula(1) i = %d formula = %s comp = %s\n", i, formula.c_str(), comp.c_str());
        if (bitflag) return formula; // Do nothing
        string newformula(formula);
        newformula.replace(newformula.begin()+30,newformula.begin()+31, "*~");
//        printf("New formula is %s\n", newformula.c_str());
        return newformula;
    }
    printf("replace_W_formula(BAD!!) i = %d formula = %s comp = %s\n", i, formula.c_str(), comp.c_str());
    return formula;
}

string replace_M_formula(const string& formula, unsigned bitflag, int i, const string& comp, map<Pin, string>& netnames, int num)
{
    int npin; // 0, 1, 2, 3, 4
    string net[5];
    int nnets = 0;
    printf("replace_M_formula i = %d formula = %s comp = %s\n", i, formula.c_str(), comp.c_str());
    for (npin = 0; npin < 5; npin++) {
        char s[8];

        unsigned k = 1; for (; k < formula.size(); k++) if (formula[k-1] == 'A' && formula[k] == (npin + '1')) break;
        if (k == formula.size()) continue;

        sprintf(s, "%c%d", "ABCD"[i/2], npin+1);
        Pin p; p.comp = comp; p.pin = s;
        if (netnames.find(p) == netnames.end()) continue;
        net[npin] = netnames[p];

        printf("Net %s connected to pin A%d\n", net[npin].c_str(), npin+1);
        nnets ++;
    }

    int cnet = 6, m1net = 6, m2net = 6;
    for (npin = 0; npin < 5; npin ++) {
        if (net[npin].find("match") < net[npin].size() || net[npin].find("GLOBAL_LOGIC0") < net[npin].size()) {
            if (m1net == 6) m1net = npin+1;
            else m2net = npin+1;
        } else if (net[npin].size() > 0) {
            if (cnet != 6) { printf("Warning, two control nets! (A%d and A%d)\n", cnet, npin+1); }
            else cnet = npin + 1;
        }
    }

    printf("m1net A%d m2net A%d cnet A%d\n", m1net, m2net, cnet);

    if (cnet == 6 || m1net == 6) {
        printf("Do not touch this formula\n");
        return formula;
    }

    char nform[32];

    if (m2net < 6) { // Of three arguments
        if (bitflag) {
            sprintf(nform,"(A%d+(A%d+A%d))", cnet, m1net, m2net);
        } else {
            sprintf(nform,"(A%d*(~A%d*~A%d))", cnet, m1net, m2net);
        }
    } else {
        if (bitflag) {
            sprintf(nform,"(A%d+A%d)", cnet, m1net);
        } else {
            sprintf(nform,"(A%d*~A%d)", cnet, m1net);
        }
    }

//    printf("New formula: %s\n", nform);
    return string(nform);
}

void fix_index_instance(Instance &in, unsigned idx, const string& comp, map<Pin, string>& netnames)
{
    int i;

    // Replacer of flip-flop initializers
    if (in.cfg.find("].GFD.GFD") < in.cfg.size()) for (i = 0; i < 8; i ++) {
        string::iterator nmbegin = lutfind_name(in.cfg, lutffnames[i],"");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        string instname(nmbegin, nmend);
        unsigned epos = instname.find("].GFD.GFD");
        unsigned spos = instname.find("BGB[");
        if (spos >= instname.size() || epos >= instname.size() || spos+4 >= epos) continue;
        if (instname[spos+4] == '0') continue; // Do not fix zero bit!
        unsigned bitno = (1 << (atoi(instname.substr(spos+4,epos-(spos+4)).c_str())));

        nmbegin = lutfind_name(in.cfg, lutfinames[i], ":");
        nmend = lutfind_end(nmbegin, in.cfg.end());
        string formula(nmbegin,nmend), newformula;

        if ((idx << 1) & bitno) {
            newformula = "SRINIT1";
        } else {
            newformula = "SRINIT0";
        }

        if (formula != newformula) {
            in.cfg.replace(nmbegin, nmend, newformula);
            printf("Replacing REXP0 formula %s to %s for %s (idx = %x, bitno =%x)\n", formula.c_str(), newformula.c_str(), instname.c_str(), idx, bitno);
        } else {
            printf("Preserving REXP0 formula %s for %s (idx = %x, bitno = %x)\n", formula.c_str(), instname.c_str(), idx, bitno);
        }
    }

    if (in.cfg.find("GMUC") >= in.cfg.size()) return; // if GMUC is not present, then do not process!
    for (i = 0; i < 8; i++) {
        string::iterator nmbegin = lutfind_name(in.cfg, lutanames[i], ":");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        unsigned lutidx = fix_index_instance_nmlookup(nmbegin, nmend); // Detect number of bit!
        string instname(nmbegin,nmend);

        // 9, 10, 11, 12, 13, 14
        if (lutidx == 0 || lutidx > 14 || lutidx == 8 || lutidx == 9) continue;

        // Extract part with formula
        nmbegin = lutfind_name(in.cfg, lutanames[i], ":#LUT:O");
        if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmend = lutfind_end(nmbegin, in.cfg.end());
        if (nmend <= nmbegin) continue;

        if (i & 1) { // (A6+~A6)*(...) - formula is inside of braces!
            if (nmend - nmbegin > 11) {
                if (string(nmbegin, nmbegin+10) == "(A6+~A6)*(") {
                    nmbegin += 10; nmend --;
                }
            }
        }

        string formula(nmbegin, nmend);
        string newformula;

        if (lutidx < 8) { // Fixing W part
            continue; // This is FOR OLD 320 Mhz version!
            //newformula = replace_W_formula( formula, (idx << 1) & (1 << lutidx), i, comp);
        } else { // Fixing Match part
            newformula = replace_M_formula( formula, (idx << 1) & (1 << (lutidx&7)), i, comp, netnames, lutidx+15);
        }
        if (formula != newformula) {
            in.cfg.replace(nmbegin, nmend, newformula);
            printf("Replacing match formula %s to %s for %s (idx = %d bit = %d)\n", formula.c_str(), newformula.c_str(), instname.c_str(), idx, (idx << 1) & (1 << (lutidx & 7)));
        } else {
            printf("Preserving match formula %s for %s (idx = %d bit = %d)\n", formula.c_str(), instname.c_str(), idx, (idx << 1) & (1 << (lutidx & 7)));
        }
    }
}

int extract_muxid(string::iterator s, string::iterator e)
{
    while (s < e && *s != '~') s++;
    while (s < e && *s == '~') s++;
    while (s < e && *s == 'A') s++;
    if (s >= e) return 0;
    return atoi(string(s,e).c_str()); // Extract MUX number
}

bool calc_formula(string::iterator& s, string::iterator e, int f[7])
{
    bool a, b;
    bool na, nb;
    char op;

    a = na = b = nb = false;

    if (s >= e) return a;
    while (s < e && *s == ')') s++;

    // Raise negation
    if (*s == '~') { // Negation sign
        s ++; na = true;
        if (s >= e) return true;
    }

    // Calculate it!
    if (*s == '(') {
        s++;
        if (calc_formula(s,e,f)) a = ! na; else a = na;
    } else if (*s == 'A') { // Value
        s++;
        if (s >= e || *s < '0' || *s > '6') return false;
        if (f[*s - '0']) a = ! na; else a = na;
        s++;
    } else if (*s == '0') {
        a = na; s++;
    } else if (*s == '1') {
        a = ! na; s++;
    }

    while (s < e && *s == ')') s++;
    if (s >= e) return a;
    op = *s; s++;
    if (s >= e) return a;

    if (*s == '~') { // Negation sign
        s ++; nb = true;
        if (s >= e) return a;
    }

    if (*s == '(') {
        s++;
        if (calc_formula(s,e,f)) b = !nb; else b = nb;
    } else if (*s == 'A') { // Value
        s++;
        if (s >= e || *s < '0' || *s > '6') return false;
        if (f[*s - '0']) b = !nb; else b = nb;
        s++;
    } else if (*s == '0') {
        b = nb; s++;
    } else if (*s == '1') {
        b = !nb; s++;
    }
    while (s < e && *s == ')') s++;

    switch (op) {
    case '+': a = a || b; break;
    case '*': a = a && b; break;
    case '@': if ( ((int)a) ^ ((int)b) ) a = true; else a = false; break;
    }

    return a;
}

int extract_regid(string::iterator s, string::iterator e, int mux_in, bool regid)
{
    if (!mux_in) return 0;
    int f[7] = {0,0,0,0,0,0,0};
    int g[3];
    string::iterator si; // extract visible entities
    for (si = s; si < e; si++) if (*si == 'A' && (si+1) < e && *(si+1) >= '0' && *(si+1) <= '5') f[*(si+1) - '0'] = 1;
    int i, gi; // extract the rest!
    for (gi = i = 0; i < 6; i++) if (f[i]) { if (gi > 2) return 0; g[gi] = i; gi ++; }

    // Execute and calculate result vector
    int rvec; // only 8 valid values can be there, that orders g[i] correctly
    rvec = 0;
    for (i = 0; i < 8; i++) {
        f[g[0]] = (i & 1) == 1; // FIT completed!
        f[g[1]] = (i & 2) == 2;
        f[g[2]] = (i & 4) == 4;
        si = s;
        if (calc_formula(si,e,f)) rvec |= (1 << i);
    }

    switch (rvec) { // All variants of MUX encoding
    case 0xca: f[0] = g[0]; f[1] = g[1]; f[2] = g[2]; break; // 11001010
    case 0xac: f[0] = g[1]; f[1] = g[0]; f[2] = g[2]; break; // 10101100
    case 0xe2: f[0] = g[0]; f[1] = g[2]; f[2] = g[1]; break; // 11100010
    case 0xb8: f[0] = g[2]; f[1] = g[0]; f[2] = g[1]; break; // 10111000
    case 0xd8: f[0] = g[2]; f[1] = g[1]; f[2] = g[0]; break; // 11011000
    case 0xe4: f[0] = g[1]; f[1] = g[2]; f[2] = g[0]; break; // 11100100
    default: break;
    }

    if (mux_in != f[2] && regid) {
        printf("WARNING, RVEC = %x MUX_IN = %d, g[0] = %d g[1] = %d, g[2] = %d, %s\n",
            rvec, mux_in, f[0], f[1], f[2], string(s,e).c_str());
    }
    if (regid) return f[0];
    return f[1];
}

static void fix_adders(Instance& in)
{
    int i;
    int muxids[4], regids[4], inids[4]; // Mux IDS, Reg IDS, IN ids
    if (in.cfg.find("ABCD0") >= in.cfg.size() && in.cfg.find("EFG0") >= in.cfg.size()) return; // NOT RELEVANT

    muxids[0] = muxids[1] = muxids[2] = muxids[3] = 0; // Muxids
    regids[0] = regids[1] = regids[2] = regids[3] = 0;
    inids[0] = inids[1] = inids[2] = inids[3] = 0;

    for (i = 0; i < 8; i++) {
        if ((i&1) == 0) continue; // Skip LUT5 when looking for mux ids
        string::iterator nmbegin = lutfind_name(in.cfg, lutanames[i], ":");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        string instname(nmbegin, nmend);
        if (instname.find("EFG0/BG[") >= instname.size() && instname.find("ABCD0/BG[") >= instname.size()) continue;
        if (instname.find("].ADDL") >= instname.size()) continue; // Invalid

        // Extract part with formula
        nmbegin = lutfind_name(in.cfg, lutanames[i], ":#LUT:O");
        if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmend = lutfind_end(nmbegin, in.cfg.end());
        if (nmend <= nmbegin) continue;
        if (nmend - nmbegin > 11) {
            if (string(nmbegin, nmbegin+10) == "(A6+~A6)*(") {
                nmbegin += 10; nmend --;
            }
        }
        muxids[i/2] = extract_muxid(nmbegin, nmend);
    }

    for (i = 0; i < 8; i++) {
        if (i&1) continue; // Skip LUT6 when looking for mux ids
        string::iterator nmbegin = lutfind_name(in.cfg, lutanames[i], ":");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        string instname(nmbegin, nmend);
        if (instname.find("EFG0/BG[") >= instname.size() && instname.find("ABCD0/BG[") >= instname.size()) continue;
        if (instname.find("].ADDL") >= instname.size()) continue; // Invalid

        // Extract part with formula
        nmbegin = lutfind_name(in.cfg, lutanames[i], ":#LUT:O");
        if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmend = lutfind_end(nmbegin, in.cfg.end());
        if (nmend <= nmbegin) continue;
        regids[i/2] = extract_regid(nmbegin, nmend, muxids[i/2], true);
        inids[i/2] = extract_regid(nmbegin, nmend, muxids[i/2], false);
    }

    for (i = 0; i < 8; i++) {
        string::iterator nmbegin = lutfind_name(in.cfg, lutanames[i], ":");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        string instname(nmbegin, nmend);
        if (instname.find("EFG0/BG[") >= instname.size() && instname.find("ABCD0/BG[") >= instname.size()) continue;
        if (instname.find("].ADDL") >= instname.size()) continue; // Invalid

        // Extract part with formula
        nmbegin = lutfind_name(in.cfg, lutanames[i], ":#LUT:O");
        if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmend = lutfind_end(nmbegin, in.cfg.end());
        if (nmend <= nmbegin) continue;

        if (i & 1) { // (A6+~A6)*(...) - formula is inside of braces!
            if (nmend - nmbegin > 11) {
                if (string(nmbegin, nmbegin+10) == "(A6+~A6)*(") {
                    nmbegin += 10; nmend --;
                }
            }
        }

        string formula(nmbegin, nmend);
        string newformula;
        if (i & 1) {
            if (inids[i/2]) {
                char s[128];
                sprintf(s, "(%s+(A%d*A%d))",formula.c_str(), muxids[i/2], inids[i/2]);
                newformula = s;
            } else {
                newformula = formula;
            }
        } else {
            if (regids[i/2]) {
                char s[128];
                sprintf(s, "A%d", regids[i/2]);
                newformula = s;
            } else {
                newformula = formula;
            }
        }

        if (formula != newformula) {
            in.cfg.replace(nmbegin, nmend, newformula);
            printf("HALFROUND_FIX Replaced %s to %s for %s\n", formula.c_str(), newformula.c_str(), instname.c_str());
        } else {
            printf("HALFROUND_FIX Kept old formula %s for %s\n", formula.c_str(), instname.c_str());
        }
    }
}

static void fix_nonces(Instance& in)
{
    if (in.cfg.find("NON") >= in.cfg.size()) return; // Fast check - if it contains any NON.. LUTs
    int i;
    for (i = 0; i < 8; i++) {
        string::iterator nmbegin = lutfind_name(in.cfg, lutanames[i], ":");
        string::iterator nmend = nmbegin;
        while (nmend < in.cfg.end() && *nmend != '\n' && *nmend != ' ' && *nmend != '\r' && *nmend != '\t' && *nmend != ':') nmend ++;
        string non(nmbegin, nmend);

        unsigned noni = non.find("NON");
        if (non.size() < 7 || noni >= non.size() - 6) continue;
        if (non[noni+4] != '/' || non[noni+5] != 'L') continue;
        if (non[noni+6] == '4' || non[noni+6] == '8') continue; // 1,2,3,5,6,7 only processed!

        // Extract part with formula
        nmbegin = lutfind_name(in.cfg, lutanames[i], ":#LUT:O");
        if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmbegin++; if (nmbegin == in.cfg.end()) continue;
        nmend = lutfind_end(nmbegin, in.cfg.end());
        if (nmend <= nmbegin) continue;

        if (i & 1) { // (A6+~A6)*(...) - formula is inside of braces!
            if (nmend - nmbegin > 11) {
                if (string(nmbegin, nmbegin+10) == "(A6+~A6)*(") {
                    nmbegin += 10; nmend --;
                }
            }
        }

        string formula(nmbegin, nmend);
        string newformula;

        unsigned fpos = formula.size()-1;
        if (fpos >= formula.size()) continue;
        if (formula[fpos] == ')') fpos --;
        if (fpos >= formula.size()) continue;
        fpos --; if (fpos >= formula.size()) continue; // digit skipped
        fpos --; if (fpos >= formula.size()) continue; // A skipped
        newformula = formula;
        if (formula[fpos] != '~' && formula[fpos] == '+') {
            newformula = formula.substr(0,fpos) + "*~" + formula.substr(fpos+1, formula.size());
        }
        if (formula != newformula) {
            in.cfg.replace(nmbegin, nmend, newformula);
            printf("NONCE Replaced %s to %s for %s\n", formula.c_str(), newformula.c_str(), non.c_str());
        } else {
            printf("NONCE Kept old formula %s for %s\n", formula.c_str(), non.c_str());
        }
    }
}

int indexfixer(void)
{
    map<unsigned, map<string, unsigned> > fixtable;

    string::size_type npos = config_file.find("-fixidx=");
    while (npos < config_file.size()) {
        npos += 8;
        string pval = chop_configname(config_file, npos);
        string::size_type pc = pval.find(",");
        if (pc < pval.size() && pc > 0) // Load prefix into table fixer
            fixtable[pc][pval.substr(0,pc)] = (unsigned)atoi(pval.substr(pc+1, pval.size()).c_str());
        npos = config_file.find("-fixidx=", npos);
    }

    Design d;
    printf("Loading design: %s\n", infile.c_str());
    if (!d.load(infile)) { printf("Unable to load design %s\n", infile.c_str()); return 1; }

    Design::insts_type::iterator ii;

    printf("Generating PIN to NET name map...\n");
    Design::nets_type::iterator ni;
    map<Pin, string> netnames;
    for (ni = d.nets.begin(); ni != d.nets.end(); ni++) {
        if (ni->second.outpin.comp.size() > 0) netnames[ni->second.outpin] = ni->first;
        for (Net::inpin_type::iterator nii = ni->second.inpin.begin(); nii != ni->second.inpin.end(); nii++)
            netnames[*nii] = ni->first;
    }

    printf("Started fixing design...\n");
    for (ii = d.insts.begin(); ii != d.insts.end(); ii++) {
        // Fix nonces in finalizer
        if (ii->first.find("C10L") < ii->first.size() || ii->first.find("CRF_") < ii->first.size()) fix_nonces(ii->second);
//        if (ii->first.find("/A0[") < ii->first.size() || ii->first.find("/E0[") < ii->first.size()) fix_adders(ii->second);
        if (ii->second.primtype == "IOB") {
            unsigned sbeg = ii->second.cfg.find("PRE_EMPHASIS::OFF");
            if (sbeg < ii->second.cfg.size()) {
                printf("Removing pre-emphasis for IOB %s\n", ii->first.c_str());
                string::iterator si = ii->second.cfg.begin() + sbeg;
                ii->second.cfg.replace(si, si+17, string()); // Remove PRE_EMPHASIS::OFF!
            }
        }
        map<unsigned, map<string, unsigned> >::reverse_iterator ri = fixtable.rbegin();
        for (;ri != fixtable.rend(); ri++) {
            if (ii->first.size() < ri->first) continue;
            map<string, unsigned>::iterator rii;
            rii = ri->second.find(ii->first.substr(0,ri->first));
            if (rii == ri->second.end()) continue;
            fix_index_instance(ii->second, rii->second, ii->first, netnames);
            break;
        }
        if (ri == fixtable.rend()) {
            string::size_type pos = ii->second.cfg.find("D5LUT:");
            string s(ii->second.cfg.substr(pos+6, 20));
            for (ri = fixtable.rbegin(); ri != fixtable.rend(); ri++) {
                if (s.size() < ri->first) continue;
                map<string, unsigned>::iterator rii;
                rii = ri->second.find(s.substr(0,ri->first));
                if (rii == ri->second.end()) continue;
                fix_index_instance(ii->second, rii->second, ii->first, netnames);
                break;
            }
        }
    }

    printf("Saving fixed design: %s\n", outfile.c_str());
    if (!d.save(outfile)) { printf("Unable to save output file %s\n", outfile.c_str()); return 1; }
    return 0;
}

int main(int ac, char **av)
{
    int i;

    for (i = 1; i < ac; i++) { config_file += " "; config_file += av[i]; } // Parse arguments into config file lines!
    string::size_type npos;
    npos = config_file.find("-cfg=");
    if (npos < config_file.size()) { // Read configuration from file
        string fn = chop_configname(config_file, npos+5);
        FILE *fd = fopen(fn.c_str(), "rb");
        if (!fd) { printf("Cannot open %s, aborting\n", fn.c_str()); return 1; }
        fseek(fd, 0L, SEEK_END);
        unsigned sz = ftell(fd);
        fseek(fd, 0L, SEEK_SET);
        string s; s.resize(sz);
        fread((void*)s.data(), s.size(), 1, fd);
        config_file += " "; config_file += s;
        fclose(fd);
    }

    printf("Run with configuration: %s\n", config_file.c_str());

    npos = config_file.find("-inf=");      if (npos < config_file.size()) infile = chop_configname(config_file, npos+5);
    npos = config_file.find("-outf=");     if (npos < config_file.size()) outfile = chop_configname(config_file, npos+6);
    npos = config_file.find("-macrobox="); if (npos < config_file.size()) { macro_boxes = parse_posrects(config_file.c_str()+npos+10); }
    npos = config_file.find("-routebox="); if (npos < config_file.size()) { routing_boxes = parse_posrects(config_file.c_str()+npos+10); }

    if (config_file.find("-place=") < config_file.size()) {
        return run_placer();
    } else  if (config_file.find("-pinswapfix=") < config_file.size()) {
        return pinswapfix();
    } else if (config_file.find("-fixidx=") < config_file.size()) {
        return indexfixer();
    } else {
        return hardmacro_gen();
    }
    return 0;
}
