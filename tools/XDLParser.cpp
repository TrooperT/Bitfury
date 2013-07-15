//
// Copyright 2012 www.bitfury.org
//
#include "XDLParser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

using namespace std;
using namespace XDL;

namespace XDL
{
    int parse_slice_x(const std::string &s)
    {
        const char *px = s.c_str();
        px = strchr(px, '_'); if (!px) px = s.c_str(); else px ++;
        px = strchr(px, 'X'); if (!px) px = s.c_str(); else px ++;
        return atoi(px);
    }
    int parse_slice_y(const std::string &s)
    {
        const char *px = s.c_str();
        px = strchr(px, '_'); if (!px) px = s.c_str(); else px ++;
        px = strchr(px, 'Y'); if (!px) px = s.c_str(); else px ++;
        return atoi(px);
    }
};


static string XDL_comma(",");
static string XDL_semicolon(";");

static string XDL_token(string::const_iterator &p, string::const_iterator e)
{
    while (p < e) {
        while (p < e && (*p == '\n' || *p == '\r' || *p == ' ' || *p == '\t')) p++; // Skip whitespaces
        switch (*p) {
            case '#': while (p < e && *p != '\n' && *p != '\r') p++; continue; // if we get
            case '\"': {
                p++;
                string::const_iterator st = p;
                while (p < e && *p != '\"') {
                    if (*p == '\\' && (p+1) < e && *(p+1) == '\"') p++;
                    p++;
                }
                string rv(st, p);
                if (p < e) p++;
                return rv;
            }
            case ',': p++; return XDL_comma;
            case ';': p++; return XDL_semicolon;
            default: {
                string::const_iterator st = p;
                while (p < e && (*p != ' ' && *p != '\n' && *p != '\r' && *p != '\t' && *p != ',' && *p != ';')) p++;
                return string(st,p);
            }
        }
    }
    return string();
}

// std::string tile, wire0, dir, wire1;
bool Pip::parse(string::const_iterator& b, string::const_iterator e)
{
    tile = XDL_token(b,e);
    wire0 = XDL_token(b,e);
    dir = XDL_token(b,e);
    wire1 = XDL_token(b,e);
    if (!tile.size() || !wire0.size() || !dir.size() || !wire1.size()) return false;
    return true;
}

void Pip::format(std::string& dst) const
{
    dst += tile; dst += " "; dst += wire0; dst += " "; dst += dir; dst += " "; dst += wire1; dst += ",\r\n";
}

bool Pin::parse(string::const_iterator& b, string::const_iterator e)
{
    comp = XDL_token(b,e);
    pin = XDL_token(b,e);
    if (!comp.size() || !pin.size()) return false;
    return true;
}

void Pin::format(std::string& dst) const
{
    dst += "\""; dst += comp; dst += "\" "; dst += pin; dst += ",\r\n";
}

bool Net::parse(string::const_iterator& b, string::const_iterator e)
{
   while (b < e) {
        string s = XDL_token(b,e);

        switch (s[0]) {
        case ';': return true;
        case ',': continue;
        case 'c': case 'C': XDL_token(b,e); continue; // Skip any config entry.
        case 'g': case 'G': pwr = "gnd"; continue;
        case 'v': case 'V': pwr = "vcc"; continue;
        case 'i': case 'I': {
            Pin p;
            if (!p.parse(b,e)) return false;
            inpin.push_back(p);
            continue;
        }
        case 'O': case 'o':
            if (!outpin.parse(b,e)) return false;
            continue;
        case 'p': case 'P': {
            Pip p;
            if (!p.parse(b,e)) return false;
            routing.push_back(p);
            continue;
        }
        default:
            return false;
        }
    }
    return true;
}

void Net::format(std::string& dst) const
{
    if (pwr.size() > 0) {
        dst += "\" "; dst += pwr; dst += ",\r\n";
    } else {
        dst += "\",\r\n";
    }

    if (outpin.comp.size() > 0) {
        dst += "    outpin ";
        outpin.format(dst);
    }

    inpin_type::const_iterator i;
    for (i = inpin.begin(); i != inpin.end(); i++) {
        dst += "    inpin ";
        i->format(dst);
    }

    routing_type::const_iterator j;
    for (j = routing.begin(); j != routing.end(); j ++) {
        dst += "    pip ";
        j->format(dst);
    }
    dst += "    ;\r\n";
}

bool Instance::parse(string::const_iterator& b, string::const_iterator e)
{
    primtype = XDL_token(b,e);
    if (XDL_token(b,e) != ",") return false;
    if (XDL_token(b,e) != "placed") return false;
    place_switch = XDL_token(b,e);
    place = XDL_token(b,e);
    if (XDL_token(b,e) == ";") return true;

    string enam = XDL_token(b,e);
    if (enam == "module") {
        module_inst = XDL_token(b,e);
        module = XDL_token(b,e);
        module_int_inst = XDL_token(b,e);
        if (XDL_token(b,e) == ";") return true;
        if (XDL_token(b,e) != "cfg") return false;
    } else if (enam != "cfg") return false;

    cfg = XDL_token(b,e);
    while (b<e && XDL_token(b,e) != ";");
    return true;
}

void Instance::format(std::string& dst) const
{
    dst += "\""; dst += primtype; dst += "\", placed ";
    dst += place_switch;
    dst += " ";
    dst += place;
    if (module_inst.size()) { dst += ",module \""; dst += module_inst; dst += "\" \""; dst += module; dst += "\" \""; dst += module_int_inst; dst += "\""; }
    if (cfg.size()) { dst += ",\r\n    cfg \""; dst += cfg; dst += "\""; }
    dst += ";\r\n";
}

bool Port::parse(string::const_iterator& b, string::const_iterator e)
{
    inst = XDL_token(b,e);
    pin = XDL_token(b,e);
    while (b < e && XDL_token(b, e) != ";") ;
    if (!inst.size() || !pin.size()) return false;
    return true;
}

void Port::format(std::string& dst) const
{
    dst += "\""; dst += inst; dst += "\" \""; dst += pin; dst += "\";\t\r\n";
}

bool Module::parse(string::const_iterator& b, string::const_iterator e)
{
    refcomp = XDL_token(b,e);
    string s = XDL_token(b,e);
    if (s == ",") {
        s = XDL_token(b,e);
        if (s[0] == 'c' || s[0] == 'C') {
            cfg = XDL_token(b,e);
        }
    }

    while (b < e) {
        s = XDL_token(b,e);

        switch (s[0]) {
        case ';': continue;
        case ',': continue;
        case 'p': case 'P': // Port
            s = XDL_token(b,e);
            if (!s.size()) return false;
            if (!ports[s].parse(b,e)) return false;
            continue;
        case 'e': case 'E': // Endmacro - finished parsing this module!
            while (b < e && XDL_token(b,e) != ";") ;
            return true;
//        case 'm': case 'M':
//            s = XDL_token(b,e);
//            if (!s.size()) return false;
//            if (!modules[s].parse(b,e)) return false;
//            continue;
        case 'n': case 'N': // Net
            s = XDL_token(b,e);
            if (!s.size()) return false;
            if (!nets[s].parse(b,e)) return false;
            continue;
        case 'i': case 'I': // Instance
            s = XDL_token(b,e);   // Get instance name!
            if (!s.size()) return false; // No instance name!
            if (!insts[s].parse(b,e)) return false;
            continue;
        default:
            return false;
        }
    }
    return true;
}

void Module::format(std::string& dst) const
{
    dst += "\" \""; dst += refcomp; dst += "\"";
    if (cfg.size()) { dst += ", cfg \""; dst += cfg; dst += "\""; }
    dst += ";\r\n";

    ports_type::const_iterator pi;
    for (pi = ports.begin(); pi != ports.end(); pi ++) {
        dst += "port \"";
        dst += pi->first;
        dst += "\" ";
        pi->second.format(dst);
    }

    insts_type::const_iterator ii;
    for (ii = insts.begin(); ii != insts.end(); ii ++) {
        dst += "inst \"";
        dst += ii->first;
        dst += "\" ";
        ii->second.format(dst);
    }

    nets_type::const_iterator ni;
    for (ni = nets.begin(); ni != nets.end(); ni ++) {
        dst += "net \"";
        dst += ni->first;
        ni->second.format(dst);
    }
}

bool Design::parse(string::const_iterator& b, string::const_iterator e)
{
    while (b < e) {
        string s = XDL_token(b,e);
        if (!s.size()) break;

        switch (s[0]) {
        case ';': continue;
        case ',': continue;
        case 'd': case 'D':
            name = XDL_token(b,e);   // Mandatory entry
            device = XDL_token(b,e); // Mandatory entry
            version = XDL_token(b,e);
            if (version == ";" || version == "") { version = ""; continue; }
            if (version == ",") version = "";
            while (b < e) {
                s = XDL_token(b,e);
                switch (s[0]) {
                case ';': break;
                case ',': continue;
                case 'c': case 'C': cfg = XDL_token(b,e); continue;
                default: return false;
                }
                break;
            }
            continue;
        case 'm': case 'M':
            s = XDL_token(b,e);
            if (!s.size()) return false;
            if (!modules[s].parse(b,e)) return false;
            continue;
        case 'n': case 'N': // Net
            s = XDL_token(b,e);
            if (!s.size()) return false;
            if (!nets[s].parse(b,e)) return false;
            continue;
        case 'i': case 'I': // Instance
            s = XDL_token(b,e);   // Get instance name!
            if (!s.size()) return false; // No instance name!
            if (!insts[s].parse(b,e)) return false;
            continue;
        default:
            return false;
        }
    }
    return true;
}

void Design::format(string& dst) const
{
    dst += "design \"";
    dst += name;
    dst += "\" ";
    dst += device;
    if (version.size()) { dst += " "; dst += version; }
    if (cfg.size()) { dst += ",\r\n    cfg \""; dst += cfg; dst += "\""; }
    dst += ";\r\n";

    modules_type::const_iterator mi;
    for (mi = modules.begin(); mi != modules.end(); mi++) {
        dst += "module \""; dst += mi->first;
        mi->second.format(dst);
        dst += "endmodule \""; dst += mi->first; dst += "\";\r\n";
    }

    insts_type::const_iterator ii;
    for (ii = insts.begin(); ii != insts.end(); ii ++) {
        dst += "inst \"";
        dst += ii->first;
        dst += "\" ";
        ii->second.format(dst);
    }

    nets_type::const_iterator ni;
    for (ni = nets.begin(); ni != nets.end(); ni ++) {
        dst += "net \"";
        dst += ni->first;
        ni->second.format(dst);
    }
}

bool Design::load(const std::string& fn)
{
    FILE *fd = fopen(fn.c_str(), "rb");
    if (!fd) return false;
    fseek(fd, 0L, SEEK_END);
    unsigned sz = ftell(fd);
    fseek(fd, 0L, SEEK_SET);
    string s; s.resize(sz);
    fread((void*)s.data(), s.size(), 1, fd);
    fclose(fd);

    string::const_iterator ci = s.begin();
    bool rv = parse(ci, s.end());

    if (!rv) {
        string::const_iterator cp = ci;
        cp += 40; if (cp >= s.end()) cp = s.end();

        printf("Parser found error at position: %u text after it:\n %s\n",
            (unsigned)(ci-s.begin()), string(ci,cp).c_str());
        return false;
    }

    return true;
}

bool Design::save(const std::string& fn)
{
    FILE *fd = fopen(fn.c_str(), "wb");
    if (!fd) return false;
    string dst;
    format(dst);
    fwrite(dst.data(), dst.size(), 1, fd);
    fclose(fd);
    return true;
}
