const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

admin.initializeApp();

const BATCH_LIMIT = 500;

async function deleteRefsInBatches(db, refs) {
  let batch = db.batch();
  let count = 0;

  for (const ref of refs) {
    batch.delete(ref);
    count++;
    if (count >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
}

async function findFollowRefsByOwnerUid(db, ownerUid) {
  // Intentionally avoid collectionGroup query to remove index dependency.
  // Account deletion is low-frequency, so a full user scan is acceptable.
  const refs = [];
  const usersSnapshot = await db.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const followsSnapshot = await userDoc.ref.collection("follows").get();
    for (const followDoc of followsSnapshot.docs) {
      if (followDoc.data().ruleSetOwnerUid === ownerUid) {
        refs.push(followDoc.ref);
      }
    }
  }
  return refs;
}

exports.deleteAccountData = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  let phase = "start";

  try {
    phase = "query_owned_rule_sets";
    const ownedSnapshot = await db
        .collection("rule_sets")
        .where("ownerUid", "==", uid)
        .get();

    if (ownedSnapshot.docs.length > 0) {
      phase = "delete_owned_rule_sets";
      const ownedRefs = ownedSnapshot.docs.map((doc) => doc.ref);
      await deleteRefsInBatches(db, ownedRefs);
    }

    // Remove follow bindings in other users that point to this owner's rulesets.
    phase = "query_follow_bindings";
    const followRefs = await findFollowRefsByOwnerUid(db, uid);
    if (followRefs.length > 0) {
      phase = "delete_follow_bindings";
      await deleteRefsInBatches(db, followRefs);
    }

    // Delete user profile and all subcollections (including own follows).
    phase = "delete_user_document_tree";
    const userDocRef = db.collection("users").doc(uid);
    await db.recursiveDelete(userDocRef);

    // Finally delete Firebase Auth account.
    phase = "delete_auth_user";
    try {
      await admin.auth().deleteUser(uid);
    } catch (error) {
      if (error?.code !== "auth/user-not-found") {
        throw error;
      }
    }

    return {
      success: true,
      deletedRuleSetCount: ownedSnapshot.docs.length,
      deletedFollowBindingCount: followRefs.length,
    };
  } catch (error) {
    logger.error("deleteAccountData failed", {
      uid,
      phase,
      code: error?.code ?? null,
      message: error?.message ?? String(error),
      stack: error?.stack ?? null,
    });
    throw new HttpsError("internal", "Failed to delete account data.");
  }
});
