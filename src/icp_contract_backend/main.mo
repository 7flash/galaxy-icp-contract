import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Array "mo:base/Array";

actor {
    type Layer = Text;
    type IPFSLink = Text;
    type User = Principal;
    type Error = Text;

    var userLayers: TrieMap.TrieMap<User, [Layer]> = TrieMap.TrieMap<User, [Layer]>(Principal.equal, Principal.hash);
    var layerLinks: TrieMap.TrieMap<Text, IPFSLink> = TrieMap.TrieMap<Text, IPFSLink>(Text.equal, Text.hash);

    public shared(msg) func createLayer(layerName: Layer, ipfsLink: IPFSLink) : async Error {
        let user = msg.caller;
        let layers = switch (userLayers.get(user)) {
            case (null) { [] };
            case (?v) { v };
        };
        if (Array.find<Layer>(layers, func (l: Layer): Bool { l == layerName }) != null) {
            return "LayerAlreadyExists";
        };
        userLayers.put(user, Array.tabulate<Layer>(Array.size(layers) + 1, func(i: Nat): Layer {
            if (i == Array.size(layers)) {
                layerName
            } else {
                layers[i]
            }
        }));
        layerLinks.put(Principal.toText(user) # layerName, ipfsLink);
        return "LayerCreated";
    };

    public query func resolveLink(user: User, layerName: Layer) : async ?IPFSLink {
        switch (userLayers.get(user)) {
            case (null) { return null; };
            case (?layers) {
                if (Array.find<Layer>(layers, func (l: Layer): Bool { l == layerName }) != null) {
                    return layerLinks.get(Principal.toText(user) # layerName);
                };
            };
        };
        return null;
    };
}

