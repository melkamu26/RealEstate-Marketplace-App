require("dotenv").config();
const functions = require("firebase-functions");
const fetch = require("node-fetch");

exports.getListings = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "*");

  const apiKey = process.env.REALTY_API_KEY;

  try {
    const response = await fetch(
      "https://realty-in-us.p.rapidapi.com/properties/v3/list",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-host": "realty-in-us.p.rapidapi.com",
          "x-rapidapi-key": apiKey
        },
        body: JSON.stringify({
          limit: 50,
          offset: 0,
          postal_code: "90004",
          status: ["for_sale", "ready_to_build"],
          sort: {
            direction: "desc",
            field: "list_date"
          }
        })
      }
    );

    const apiJson = await response.json();

    // 🔥 The REAL results path
    const results = apiJson?.data?.home_search?.results || [];

    // 🔥 WHAT FLUTTER EXPECTS
    return res.status(200).json({
      results: results
    });

  } catch (err) {
    return res.status(500).json({ error: err.toString() });
  }
});
